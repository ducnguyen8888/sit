package act.sit;

import java.sql.Connection;
import java.sql.PreparedStatement;

import act.util.Connect;


/**
 * Created by Duc.Nguyen on 10/8/2018.
 */
public class SITSale {
    public SITSale(){}

    public SITSale(String dataSource, String can, String saleDate,
                   String modelYear, String make,
                   String vinNo, String saleType,
                   String buyerName, String salesPrice,
                   String taxAmount, String clientId,
                   String year, String month,
                   String salesSeq, String status,
                   String reportSeq, String uptv,
                   String pendingPayment, String inputDate,
                   String opercode){
        this.set(dataSource, can, saleDate,
                modelYear, make,
                vinNo, saleType,
                buyerName, salesPrice,
                taxAmount, clientId,
                year, month,
                salesSeq, status,
                reportSeq, uptv,
                pendingPayment, inputDate,
                opercode);

    }

    public void set(String dataSource, String can, String saleDate,
                    String modelYear, String make,
                    String vinNo, String saleType,
                    String buyerName, String salesPrice,
                    String taxAmount, String clientId,
                    String year, String month,
                    String salesSeq, String status,
                    String reportSeq, String uptv,
                    String pendingPayment, String inputDate,
                    String opercode) {
        this.dataSource     = dataSource;
        this.can            = can;
        this.saleDate       = saleDate;
        this.modelYear      = modelYear;
        this.make           = make;
        this.vinNo          = vinNo;
        this.saleType       = saleType;
        this.buyerName      = buyerName;
        this.salesPrice     = salesPrice;
        this.taxAmount      = taxAmount;
        this.clientId       = clientId;
        this.year           = year;
        this.month          = month;
        this.salesSeq       = salesSeq;
        this.status         = status;
        this.reportSeq      = reportSeq;
        this.uptv           = uptv;
        this.pendingPayment = pendingPayment;
        this.inputDate      = inputDate;
        this.opercode       = opercode;
    }

    public void addSale() throws Exception{
        try ( Connection conn = Connect.open( dataSource );
              PreparedStatement ps = conn.prepareStatement(
                                          " Insert into sit_sales( "
                                        + "    can, date_of_sale,"
                                        + "    model_year, make,"
                                        + "    vin_serial_no,"
                                        + "    sale_type,"
                                        + "    purchaser_name,"
                                        + "    sales_price,"
                                        + "    tax_amount,"
                                        + "    client_id,"
                                        + "    year, month,"
                                        + "    sales_seq,"
                                        + "    status,"
                                        + "    report_seq,"
                                        + "    uptv_factor,"
                                        + "    pending_payment,"
                                        + "    input_date,"
                                        + "    opercode,"
                                        + "    chngdate )"
                                        + "  Values (?,TO_DATE(?, 'mm/dd/yyyy'),?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,TO_DATE(?, 'mm/dd/yyyy'), UPPER(?) , CURRENT_TIMESTAMP) ");
        ){
            ps.setString( 1, can );
            ps.setString( 2, saleDate );
            ps.setString( 3, modelYear );
            ps.setString( 4, make );
            ps.setString( 5, vinNo );
            ps.setString( 6, saleType );
            ps.setString( 7, buyerName );
            ps.setString( 8, salesPrice );
            ps.setString( 9, taxAmount );
            ps.setString( 10, clientId );
            ps.setString( 11, year );
            ps.setString( 12, month );
            ps.setString( 13, salesSeq );
            ps.setString( 14, status );
            ps.setString( 15, reportSeq );
            ps.setString( 16, uptv );
            ps.setString( 17, pendingPayment );
            ps.setString( 18, inputDate );
            ps.setString( 19, opercode );

            if ( ! (ps.executeUpdate() > 0) ) {
                throw new Exception("Failed to add the inventory sales");
            }
        } catch(Exception e){
            throw e;
        }
    }

    private String      dataSource          = null;
    private String      can                 = null;
    private String      saleDate            = null;
    private String      modelYear           = null;
    private String      make                = null;
    private String      vinNo               = null;
    private String      saleType            = null;
    private String      buyerName           = null;
    private String      salesPrice          = null;
    private String      taxAmount           = null;
    private String      clientId            = null;
    private String      year                = null;
    private String      month               = null;
    private String      salesSeq            = null;
    private String      status              = null;
    private String      reportSeq           = null;
    private String      uptv                = null;
    private String      pendingPayment      = null;
    private String      inputDate           = null;
    private String      opercode            = null;
    private String      chngDate            = null;


}
