package act.sit;

import act.util.Connect;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.text.SimpleDateFormat;


public class Dealership
{
    public Dealership() {}
    public Dealership(String datasource, String clientId, String can) throws Exception
    {
            this.datasource = datasource;
            this.clientId   = clientId;
            set(can);
    }
    public Dealership(String datasource, String clientId, ResultSet rs) throws SQLException
    {
        this.datasource = datasource;
        this.clientId   = clientId;
        this.set(rs);
    }

    protected   String          datasource          = null;
    protected   String          clientId            = null;

    public      String          can                 = null;
    public      String          type                = null;
    public      String          aprdistacc          = null;

    public      int             dealerType          = 0;
    public      String          category            = null;
    public      String          categoryName        = null;
    public      String          formName            = null;

    public      String          nameline1           = null;
    public      String          nameline2           = null;
    public      String          nameline3           = null;
    public      String          nameline4           = null;
    public      String          city                = null;
    public      String          state               = null;
    public      String          zipcode             = null;

    public      String          country             = null;

    public      String          phone               = null;
    public      String          email               = null;

    public      String          anameline1          = null;
    public      String          anameline2          = null;
    public      String          anameline3          = null;
    public      String          anameline4          = null;
    public      String          acity               = null;
    public      String          astate              = null;
    public      String          azipcode            = null;


    public      String          startDate           = null;
    public      String          startYear           = null;
    public      String          startMonth          = null;

    public      String[]        years               = null;


    SimpleDateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy");
    protected void set(ResultSet rs) throws SQLException
    {   can                 = rs.getString("can");
        type                = rs.getString("dealer_type");
        dealerType          = rs.getInt   ("dealer_type");
        aprdistacc          = rs.getString("aprdistacc");

        nameline1           = rs.getString("nameline1");
        nameline2           = rs.getString("nameline2");
        nameline3           = rs.getString("nameline3");
        nameline4           = rs.getString("nameline4");

        city                = rs.getString("city");
        state               = rs.getString("state");
        zipcode             = rs.getString("zipcode");
        country             = rs.getString("country");

        phone               = rs.getString("phone");
        email               = rs.getString("email");

        anameline1          = rs.getString("anameline1");
        anameline2          = rs.getString("anameline2");
        anameline3          = rs.getString("anameline3");
        anameline4          = rs.getString("anameline4");

        acity               = rs.getString("acity");
        astate              = rs.getString("astate");
        azipcode            = rs.getString("azip");

        startDate           = dateFormat.format(rs.getDate("startDate"));
        startYear           = rs.getString("startYear");
        startMonth          = rs.getString("startMonth");

        years               = rs.getString("yearList").split(",");

        switch ( dealerType )
        {
            case 1  :   category = "MV";
                        categoryName = "Motor Vehicle";
                        formName = "50-246";
                        break;

            case 2  :   category = "VM";
                        categoryName = "Vessel, Trailer, and Outboard";
                        formName = "50-260";
                        break;

            case 3  :   category = "HE";
                        categoryName = "Heavy Equipment";
                        formName = "50-266";
                        break;

            case 4  :   category = "MH";
                        categoryName = "Retail Manufactured Housing";
                        formName = "50-268";
                        break;

            default :   category = "MV";
                        categoryName = "Motor Vehicle";
                        formName = "50-246";
                        break;
        }
    }


    protected void set(String can) throws Exception
    {   try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "with "
                                            + "    dealership (client_id, can, year, yearList) "
                                            + "    as  (select client_id, can, max(year), "
                                            + "                listagg(year,',') within group (order by year) as year "
                                            + "          from  owner "
                                            + "         group by "
                                            + "                client_id, can "
                                            + "        ) "
                                            + "select  owner.can, taxdtl.dealer_type, taxdtl.aprdistacc, "
                                            + "        owner.city, owner.state, owner.zipcode, owner.country, "
                                            + "        owner.nameline1, owner.nameline2, owner.nameline3, owner.nameline4, "
                                            + "        owner.phone, owner.email, "
                                            + "        owner.anameline1, owner.anameline2, owner.anameline3, owner.anameline4, "
                                            + "        owner.acity, owner.astate, owner.azip, "
                                            + "        dealership.yearList, "
                                            + "        nvl(taxdtl.start_date,to_date('12/31/'||(taxdtl.year-1),'mm/dd/yyyy')) as \"startDate\", "
                                            + "        nvl(extract(year from taxdtl.start_date),taxdtl.year-1) as \"startYear\", "
                                            + "        nvl(extract(month from taxdtl.start_date),12) as \"startMonth\" "
                                            + "  from  dealership "
                                            + "        join owner "
                                            + "             on (owner.client_id=dealership.client_id and owner.can=dealership.can and owner.year=dealership.year) "
                                            + "        join taxdtl "
                                            + "             on (taxdtl.client_id=owner.client_id and taxdtl.can=owner.can and taxdtl.year=owner.year) "
                                            + " where  dealership.client_id=? and dealership.can=?"
                                            );
            )
        {
            ps.setString(1, clientId);
            ps.setString(2, can);

            try ( ResultSet rs = ps.executeQuery(); )
            {   if ( ! rs.next() )
                {
                    throw new Exception("No dealership was found for the specified account number");
                }

                set(rs);
            }
        }

        return;
    }

    public String toString()
    {
        StringBuilder buffer = new StringBuilder();
        buffer.append(String.format("<tr><td>%s</td><td>%s</td>", can, type));
        buffer.append(String.format("<td>%s<br>%s<br>%s<br>%s<br>%s<br>%s<br>%s<br>%s<br><br>%s<br>%s</td>",
                                    nameline1, nameline2, nameline3, nameline4, city, state, zipcode, country,
                                    phone, email
                                    )
                        );
        buffer.append(String.format("<td>%s<br>%s<br>%s<br>%s<br>%s<br>%s<br>%s</td>",
                                    anameline1, anameline2, anameline3, anameline4, acity, astate, azipcode
                                    )
                        );
        buffer.append(String.format("<td>%s</td></tr>", String.join("<br>",years)));

        return buffer.toString();
    }


// Compatability.....
    public Dealership (String can, int dealerType, String [] dealerYears, String nameline1, String nameline2, String nameline3, String nameline4, String city, String state,
                       String country, String zipcode, String phone){
        this.can = can;
        this.dealerType = dealerType;
        this.years = dealerYears;
        this.nameline1 = nameline1;
        this.nameline2 = nameline2;
        this.nameline3 = nameline3;
        this.nameline4 = nameline4;
        this.city = city;
        this.state = state;
        this.country = country;
        this.zipcode = zipcode;
        this.phone = phone;

    }
    public Dealership (String can, int dealerType, String [] dealerYears, String nameline1, String nameline2, String nameline3, String nameline4, String city, String state,
               String country, String zipcode, String phone, String aprdistacc){
        this.can = can;
        this.dealerType = dealerType;
        this.years = dealerYears;
        this.nameline1 = nameline1;
        this.nameline2 = nameline2;
        this.nameline3 = nameline3;
        this.nameline4 = nameline4;
        this.city = city;
        this.state = state;
        this.country = country;
        this.zipcode = zipcode;
        this.phone = phone;
        this.aprdistacc = aprdistacc;
    }
    public Dealership(String can, String nameline1, String nameline2,
            String nameline3, String nameline4, String city, String state,
            String country, String zipcode, String phone, String year) {

        this.can = can;
        this.nameline1 = nameline1;
        this.nameline2 = nameline2;
        this.nameline3 = nameline3;
        this.nameline4 = nameline4;
        this.city = city;
        this.state = state;
        this.country = country;
        this.zipcode = zipcode;
        this.phone = phone;
        //this.year = year;
        this.years = new String[] { year };
    }
}
