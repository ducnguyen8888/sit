package act.sit;

import java.sql.Connection;
import java.sql.PreparedStatement;

/**
 * Created by Duc.Nguyen on 11/28/2018.
 */
public class AnnualStatement extends SITStatement {

    public AnnualStatement(){}

    public AnnualStatement setSalesInfo(String inventorySaleUnits,
                                        String fleetSaleUnits,
                                        String dealerSaleUnits,
                                        String subsequentSaleUnits,
                                        String retailSaleUnits,
                                        String inventorySaleAmount,
                                        String fleetSaleAmount,
                                        String dealerSaleAmount,
                                        String subsequentSaleAmount,
                                        String retailSaleAmount){

        this.inventorySaleUnits     = inventorySaleUnits;
        this.fleetSaleUnits         = fleetSaleUnits;
        this.dealerSaleUnits        = dealerSaleUnits;
        this.subsequentSaleUnits    = subsequentSaleUnits;
        this.retailSaleUnits        = retailSaleUnits;

        this.inventorySaleAmount    = inventorySaleAmount;
        this.fleetSaleAmount        = fleetSaleAmount;
        this.dealerSaleAmount       = dealerSaleAmount;
        this.subsequentSaleAmount   = subsequentSaleAmount;
        this.retailSaleAmount       = retailSaleAmount;

        return this;
    }

    public boolean importedRecords = false;

    public String   inventorySaleUnits       = null;
    public String   fleetSaleUnits           = null;
    public String   dealerSaleUnits          = null;
    public String   subsequentSaleUnits      = null;
    public String   retailSaleUnits          = null;


    public String   inventorySaleAmount      = null;
    public String   fleetSaleAmount          = null;
    public String   dealerSaleAmount         = null;
    public String   subsequentSaleAmount     = null;
    public String   retailSaleAmount         = null;


    public AnnualStatement updateStatementStatus(Connection conn,
                                                 String clientId,
                                                 String can,
                                                 String year,
                                                 String user,
                                                 String inventorySaleUnits,
                                                 String fleetSaleUnits,
                                                 String dealerSaleUnits,
                                                 String subsequentSaleUnits,
                                                 String retailSaleUnits,
                                                 String inventorySaleAmount,
                                                 String fleetSaleAmount,
                                                 String dealerSaleAmount,
                                                 String subsequentSaleAmount,
                                                 String retailSaleAmount
                                                 ) throws Exception {

        try (PreparedStatement ps = conn.prepareStatement(
                                                "update sit_sales_master"
                                              + " set report_status = 'C',"
                                              + "      inventory_sales_units = ?,"
                                              + "      fleet_sales_units = ?,"
                                              + "      dealer_sales_units = ?,"
                                              + "      subsequent_sales_units = ?,"
                                              + "      retail_sales_units = ?,"
                                              + "      inventory_sales_amount = ?,"
                                              + "      fleet_sales_amount = ?,"
                                              + "      dealer_sales_amount = ?,"
                                              + "      subsequent_sales_amount = ?,"
                                              + "      retail_sales_amount = ?,"
                                              + "      finalize_date=CURRENT_TIMESTAMP, "
                                              + "      chngdate = sysdate,"
                                              + "      opercode = decode(opercode,'LOAD', 'LOAD',UPPER(?) )"
                                              + "  where client_id=? and can=? and month=? and year=? "
                                                            );){
            ps.setString(1, inventorySaleUnits);
            ps.setString(2, fleetSaleUnits);
            ps.setString(3, dealerSaleUnits);
            ps.setString(4, subsequentSaleUnits);
            ps.setString(5, retailSaleUnits);

            ps.setString(6, inventorySaleAmount);
            ps.setString(7, fleetSaleAmount);
            ps.setString(8, dealerSaleAmount);
            ps.setString(9, subsequentSaleAmount);
            ps.setString(10, retailSaleAmount);

            ps.setString(11, user);
            ps.setString(12, clientId);
            ps.setString(13, can);
            ps.setString(14, month);
            ps.setString(15, year);

            if ( !(ps.executeUpdate() > 0)) throw new Exception("Unable to update the annual statement status with the imported records");

        } catch (Exception e){
            throw e;
        }

        return  this;
    }


    public AnnualStatement writeToSitSalesMaster(){
        return this;
    }
    public AnnualStatement closeStatement(){

        return this;
    }
}
