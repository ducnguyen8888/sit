package act.sit;

import act.util.Connect;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;

/**
 * Created by Duc.Nguyen on 10/16/2018.
 */
public class Search {
    public Search(){}
    public Search(String dealerNo,
                          String dealerName,
                          String dealerAddress,
                          String userName,
                          String userId )  {
        this.setDealerNo(dealerNo)
                .setDealerName(dealerName)
                .setDealerAddress(dealerAddress)
                .setUserName(userName)
                .setUserId(userId);
    }

    public Search searchDealerships(String datasource,
                                    String username,
                                    String password
                                    ) throws  Exception {
        try (Connection conn  = Connect.open(datasource, username, password);) {
            return searchDealerships(conn);
        }
    }

    public Search searchDealerships(String datasource, String clientId) throws  Exception{
        this.setClientId(clientId);
        try ( Connection conn  = Connect.open(datasource);){
            return searchDealerships(conn);
        }
    }

    public Search searchDealerships(String datasource) throws  Exception{
        try ( Connection conn  = Connect.open(datasource);){
            return searchDealerships(conn);
        }
    }

    public Search searchDealerships(Connection conn) throws Exception {
        dealerships.clear();

        try (
             PreparedStatement ps  = conn.prepareStatement(
                     "with "
                             + "    dealerships (client_id, userid, username, can, year, yearList) "
                             + "    as  (select ownership.client_id, ownership.userid, sit_users.username, ownership.can, max(owner.year), "
                             + "                listagg(owner.year,',') within group (order by owner.year) as year "
                             + "          from  sit_ownership_username ownership "
                             + "                join sit_users"
                             + "                     on (sit_users.client_id = ownership.client_id and sit_users.userid = ownership.userid)"
                             + "                join owner "
                             + "                     on (owner.client_id=ownership.client_id and owner.can=ownership.can) "
                             + "         where  ownership.active='Y' "
                             + "         group by "
                             + "                ownership.client_id, ownership.userid, sit_users.username, ownership.can "
                             + "        ) "
                             + "select distinct owner.can, taxdtl.dealer_type, taxdtl.aprdistacc, "
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
                             + " where  dealerships.client_id=?"
                             + "           and dealerships.can like nvl( UPPER(?), dealerships.can )"
                             + "           and owner.nameline1 like nvl ( UPPER(?), owner.nameline1 )"
                             + "           and owner.nameline2 || ' ' || owner.nameline3 || ' ' || owner.nameline4 like nvl( UPPER(?), owner.nameline2 || ' ' || owner.nameline3 || ' ' || owner.nameline4 )"
                             + "           and dealerships.userid like nvl ( UPPER(?),dealerships.userid ) "
                             + "           and dealerships.username like nvl( UPPER(?), dealerships.username )"
                             + " order by "
                             + "        owner.can asc, owner.nameline1 asc"
             );
        )
        {   ps.setString(1, clientId);
            ps.setString(2, sanitize(dealerNo)+"%");
            ps.setString(3, sanitize(dealerName)+"%");
            ps.setString(4, "%"+sanitize(dealerAddress)+"%");
            ps.setString(5, sanitize(userId)+"%");
            ps.setString(6, sanitize(userName)+"%");

            try (ResultSet rs = ps.executeQuery(); )
            {   if ( ! rs.next() )
            {  return this;
            }

                dealerships.add(new Dealership(datasource, clientId, rs));
                while ( rs.next() )
                {   dealerships.add(new Dealership(datasource, clientId, rs));
                }
            }
        }

        return this;
    }

    public String sanitize(String value ) {
        return value.replaceAll("[\\.,\']","%").trim();
    }

    public Search setDealerNo(String dealerNo){
        this.dealerNo = dealerNo;
        return this;
    }

    public Search setDealerName(String dealerName){
        this.dealerName = dealerName;
        return this;
    }

    public Search setDealerAddress(String dealerAddress){
        this.dealerAddress = dealerAddress;
        return this;
    }

    public Search setUserName(String userName){
        this.userName = userName;
        return this;
    }

    public Search setUserId(String userId){
        this.userId = userId;
        return this;
    }

    public Search setClientId(String clientId){
        this.clientId = clientId;
        return this;
    }

    protected   String dealerNo      = null;
    protected   String dealerName    = null;
    protected   String dealerAddress = null;
    protected   String userName      = null;
    protected   String userId        = null;

    protected   String clientId      = null;
    protected   String datasource    = null;

    public ArrayList<Dealership> dealerships         = new ArrayList<Dealership>();


}
