package act.sit;

import act.util.Connect;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import java.sql.Statement;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.Map;

/*
    Need to be able to:
    
        - Search for dealer by CAN
        - Retrieve/auto-generate Address output for each dealer
        - Create/use JSON for listing of Dealerships?  Need to ensure no quotes, single or double
        - Create RECENT object that holds a dealer
            * when dealer added it's added to top, if it already exists it moves to top
            * retrieve/auto-generate recents widget for display (can/name)
*/
public class SITAccount
{
    public SITAccount(){}
    public static void main(String [] args) throws  Exception{
        SITAccount account = new SITAccount();
        for (String [] pref : account.globalPreferences){
            System.out.println(pref[0]);
            System.out.println(pref[1]);
            System.out.println(pref[2]);
        }
    }
    public SITAccount(String datasource, String clientId, String userName, String pin) throws Exception
    {
        this.datasource = datasource;
        this.clientId   = clientId;

        user = new SITUser(datasource, clientId, userName, pin);
        user.login();
        if ( user.isValid() )
        {   dealerships     = new ArrayList<Dealership>();
            if (!user.viewOnly() ){
                loadDealerships();
            }
            preferences = new Hashtable<String,String>();
            loadPreferences();
        }
    }

    protected   String                  datasource          = null;
    protected   String                  clientId            = null;

    protected   SITUser                 user                = null;
    public      ArrayList<Dealership>   dealerships         = null;

    public      Map<String,String>      preferences         = null;
    public      String[][]              sitPreferences      = new String[][] {
                                                                        {"SIT_FINALIZE_ON_PAY", "N" },
                                                                        {"SHOW_CAD_NO_IN_SIT_PORTAL","N"},
                                                                        {"SIT_SHOW_PRINT_PAY_FORM_BUTTON","N"},
                                                                        {"CSV_FILE_FORMAT_FOR_SIT_PORTAL","1"},
                                                                        {"JUR_EMAIL_ADDRESS",""},
                                                                        {"JUR_ADDRESS1",""},
                                                                        {"JUR_ADDRESS2",""},
                                                                        {"JUR_ADDRESS4",""},
                                                                        {"JUR_PHONE1",""}

                                                                    };

    public      String[][]             globalPreferences    = new String [][]{
                                                                         {"WEB_REPORTS_LOC","WEB_DIR","dev60temp"}
                                                                    };
    public String getPreference(String preferenceName)
    {
        return preferences.get(preferenceName);
    }

    public      boolean                 SIT_FINALIZE_ON_PAY             = false;
    public      boolean                 SHOW_CAD_NO_IN_SIT_PORTAL       = false;
    public      boolean                 SIT_SHOW_PRINT_PAY_FORM_BUTTON  = false;
    public      boolean                 CSV_FILE_FORMAT_FOR_SIT_PORTAL  = true;
    public      String                  WEB_DIR                         = null;

    public      String                  JUR_EMAIL_ADDRESS               = null;
    public      String                  JUR_ADDRESS1                    = null;
    public      String                  JUR_ADDRESS2                    = null;
    public      String                  JUR_ADDRESS4                    = null;
    public      String                  JUR_PHONE1                      = null;


    public boolean isValid()
    {   return user != null && user.isValid();
    }

    public boolean isLoggedIn()
    {   return user != null && user.isLoggedIn();
    }

    public      String          getDataSource()         { return datasource; }
    public      String          getClientId()           { return clientId; }

    public      SITUser         getUser()               { return user; }


    public void loadDealerships() throws Exception
    {   dealerships.clear();

        if ( ! this.isValid() ) throw new Exception("SIT user is not valid");

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "with "
                                            + "    dealerships (client_id, userid, can, year, yearList) "
                                            + "    as  (select ownership.client_id, ownership.userid, ownership.can, max(owner.year), "
                                            + "                listagg(owner.year,',') within group (order by owner.year) as year "
                                            + "          from  sit_ownership_username ownership "
                                            + "                join owner "
                                            + "                     on (owner.client_id=ownership.client_id and owner.can=ownership.can) "
                                            + "         where  ownership.active='Y' "
                                            + "         group by "
                                            + "                ownership.client_id, ownership.userid, ownership.can "
                                            + "        ) "
                                            + "select  owner.can, taxdtl.dealer_type, taxdtl.aprdistacc, "
                                            + "        owner.city, owner.state, owner.zipcode, owner.country, "
                                            + "        owner.nameline1, owner.nameline2, owner.nameline3, owner.nameline4, "
                                            + "        owner.phone, owner.email, "
                                            + "        owner.anameline1, owner.anameline2, owner.anameline3, owner.anameline4, "
                                            + "        owner.acity, owner.astate, owner.azip, "
                                            + "        dealerships.yearList, "
                                            + "        nvl(taxdtl.start_date,to_date('12/31/'||(taxdtl.year-1),'mm/dd/yyyy')) as \"startDate\", "
                                            + "        nvl(extract(year from taxdtl.start_date),taxdtl.year-1) as \"startYear\", "
                                            + "        nvl(extract(month from taxdtl.start_date),12) as \"startMonth\" "
                                            + "  from  dealerships "
                                            + "        join owner "
                                            + "             on (owner.client_id=dealerships.client_id and owner.can=dealerships.can "
                                            + "                   and owner.year=dealerships.year) "
                                            + "        join taxdtl "
                                            + "             on (taxdtl.client_id=owner.client_id and taxdtl.can=owner.can and taxdtl.year=owner.year) "
                                            + " where  dealerships.client_id=? and dealerships.userid=? "
                                            + " order by "
                                            + "        owner.can asc, owner.nameline1 asc"
                                            );
            )
        {   ps.setString(1, clientId);
            ps.setString(2, user.getUserId());

            try ( ResultSet rs = ps.executeQuery(); )
            {   if (  !rs.next() )
                {   throw new Exception("No dealerships were found for the user");
                }

                dealerships.add(new Dealership(datasource, clientId, rs));
                while ( rs.next() )
                {   dealerships.add(new Dealership(datasource, clientId, rs));
                }
            }
        }

        return;
    }


    public void setPreferences()
    {
        SIT_FINALIZE_ON_PAY             = "Y".equalsIgnoreCase(getPreference("SIT_FINALIZE_ON_PAY"));
        SHOW_CAD_NO_IN_SIT_PORTAL       = "Y".equalsIgnoreCase(getPreference("SHOW_CAD_NO_IN_SIT_PORTAL"));
        SIT_SHOW_PRINT_PAY_FORM_BUTTON  = "Y".equalsIgnoreCase(getPreference("SIT_SHOW_PRINT_PAY_FORM_BUTTON"));
        CSV_FILE_FORMAT_FOR_SIT_PORTAL  = "1".equalsIgnoreCase(getPreference("CSV_FILE_FORMAT_FOR_SIT_PORTAL"));
        WEB_DIR                         = getPreference("WEB_DIR");
        JUR_EMAIL_ADDRESS               = getPreference("JUR_EMAIL_ADDRESS");
        JUR_ADDRESS1                    = getPreference("JUR_ADDRESS1");
        JUR_ADDRESS2                    = getPreference("JUR_ADDRESS2");
        JUR_ADDRESS4                    = getPreference("JUR_ADDRESS4");
        JUR_PHONE1                      = getPreference("JUR_PHONE1");
    }
    public void loadPreferences() throws Exception
    {
        if ( preferences == null )
        {
            preferences = new Hashtable<String,String>();
        }
        preferences.clear();

        if ( ! this.isValid() ) throw new Exception("SIT user is not valid");

        try ( Connection        con  = Connect.open(datasource);) {

            try (
                    PreparedStatement ps = con.prepareStatement(
                            "select nvl(sit_get_codeset_value(?,'DESCRIPTION','CLIENT',?),?) as \"value\" from dual"
                    );
            ) {
                ps.setString(1, clientId);

                for (String[] preference : sitPreferences) {
                    ps.setString(2, preference[0]); // preference name
                    ps.setString(3, preference[1]); // default value

                    try (ResultSet rs = ps.executeQuery();) {
                        preferences.put(preference[0], (rs.next() ? nvl(rs.getString("value"), preference[1]) : preference[1]));
                    }
                }
            }

            try (
                    PreparedStatement ps = con.prepareStatement(
                            "select nvl(description,?) as \"value\" from global_codeset"
                                    + " where type_code = ? "
                                    + "       and code = ?"
                                    + "       and sysdate < nvl(obsolete_date,sysdate + 1)"
                    );
            ) {
                for (String[] preference : globalPreferences) {
                    ps.setString(1, preference[2]);// default value
                    ps.setString(2, preference[0]);// type-code
                    ps.setString(3, preference[1]);//code

                    try (ResultSet rs = ps.executeQuery();) {
                        preferences.put(preference[1], (rs.next() ? nvl(rs.getString("value"), preference[2]) : preference[2]));
                    }
                }
            }
            setPreferences();
        }

        return;
    }


    public String toString()
    {
        StringBuilder builder = new StringBuilder();

        if ( dealerships == null ) return "no dealers";

        builder.append("<table cellpadding='2' border='1'>");
        for ( Dealership dealership : dealerships )
        {
            builder.append(dealership.toString());
        }
        builder.append("</table>");

        return builder.toString();
    }

    public String nvl(String... values)
    {
        if ( values == null ) return "";
        for ( String value : values )
        {
            if ( value != null ) return value;
        }
        return "";
    }

    public boolean isDefined(String... values)
    {   if ( values == null || values.length == 0 ) return false;
        for ( String value : values )
        {   if ( value == null || value.length() == 0 ) return false;
        }
        return true;
    }


    public static String[][] getSITClients(String datasource) throws Exception
    {
        ArrayList<String[]> clients = new ArrayList<String[]>();

        try ( Connection con = Connect.open(datasource);
                Statement st = con.createStatement();
                ResultSet rs = st.executeQuery(
                                              "select distinct client.client_id, client.client_name "
                                            + "  from sit_users join client on (client.client_id=sit_users.client_id) "
                                            + " order by client.client_name"
                                            );
            )
        {
            while ( rs.next() )
            {
                String[] client = new String[] { rs.getString("client_id"), rs.getString("client_name") };
                clients.add(client);
            }
        }

        return (String[][])clients.toArray(new String[0][0]);
    }

}
