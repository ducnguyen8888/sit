package act.sit;

import act.util.Connect;

import java.util.ArrayList;
import java.sql.*;

/**
 * Created by Duc.Nguyen on 10/19/2018.
 */
public class SITSales extends ArrayList<SITSale> {

    public static void main(String [] args) throws  Exception{
        Connection conn = Connect.open("jdbc:oracle:thin:@ares:1521/actd","sit_inq","texas1");
        ArrayList<SITSale> sales =  SITSales.initialContext().retrieveSitSales(conn,"99B03507000000000","2017");

        for (SITSale sale : sales){
            System.out.println("Type:"+sale.saleType+" "+"Total Sale: "+sale.totalSale+" "+ "Total Amount: "+ sale.totalAmount);
        }
    }


    public SITSales(){
        super();
    }

    public static SITSales initialContext(){
        return new SITSales();
    }

    public SITSale get(String saleType) {
        if ( saleType != null){
            for ( SITSale sitSale : this ){
                if ( sitSale.saleType.equals( saleType) ){
                    return sitSale;
                }
            }
        }

        return null;
    }

    public SITSales retrieveSitSales(String datasource,
                                        String can,
                                        String year
                                        ) throws  Exception {
        try (Connection conn = Connect.open(datasource);){
            return retrieveSitSales(conn, can, year);
        }
    }


    public SITSales retrieveSitSales(Connection conn,
                                        String can,
                                        String year
                                        ) throws  Exception{
        try ( PreparedStatement ps = conn.prepareStatement(
                                               "select count(can)totalSale,"
                                              + "      to_char(sum(sales_price), '$999,999,999.00') amount,"
                                              + "      sale_type"
                                              + " from   sit_sales "
                                              + " where  can = ?"
                                              + "          and year=?"
                                              + "          and status <> 'D' "
                                              + " group by sale_type"
                                              + " order by sale_type");

        ){
            ps.setString(1, can);
            ps.setString(2, year);

            try ( ResultSet rs = ps.executeQuery() ) {
                if ( !rs.isBeforeFirst() ) throw  new Exception("Unable to retrieve sit sales");

                while ( rs.next() ) {
                    this.add( SITSale.initialContext().setSaleType( rs.getString("sale_type"))
                                                        .setTotalSale( rs.getString("totalSale"))
                                                        . setTotalAmount( rs.getString("amount"))
                                                        );
                }
            }



        }

        return this;
    }

    public SITSale sitSale = null;



}
