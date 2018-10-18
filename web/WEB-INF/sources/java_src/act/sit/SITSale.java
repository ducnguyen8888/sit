package act.sit;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import act.util.Connect;


/**
 * Created by Duc.Nguyen on 10/8/2018.
 */
public class SITSale {
    public SITSale(){}

    public static  void main(String [] args){
        try {
            Connection conn = Connect.open("jdbc:oracle:thin:@ares:1521/actd","sit_inq","texas1");
            System.out.println("Connected successfully");
            //SITSale sitSale = SITSale.initialContext().;
            //sitSale.addSale(conn);
            SITSale sitSale = SITSale.initialContext().set("P138386","09.1.2018","2019","Lexus","1234567890","MV","test","25000","55","2000","2018","08","O","1","Y","10.15.2018","Claude")
                                     .addSale(conn);
          //  System.out.println(sitSale.salesSeq);
          //  System.out.println(sitSale.uptv);
          //  System.out.println(sitSale.saleDate);
         //   SITSale sitSale = SITSale.initialContext()
                                   // .setSaleDate("10.02.2018")
                                   // .setSaleType("MV")
                                   // .setModelYear("2019")
                                   // .setMake("BMW")
                                   // .setVinNo("9876543210")
                                   // .setSalesPrice("45000")
                                   // .setTaxAmount("123.36")
                                   // .setBuyerName("TEST")
                                   // .setInputDate("10.15.2018")
                                   // .setMonth("08")
                                   // .setYear("2018")
                                   // .setClientId("2000")
                                   // .setCan("P138386")
                                   // .setSalesSeq("1463")
                                   // .setOpercode("Claude").updateSale(conn);



        } catch ( Exception e){
            System.out.println( e.toString());
        }

    }

    public SITSale set(String can, String saleDate,
                    String modelYear, String make,
                    String vinNo, String saleType,
                    String buyerName, String salesPrice,
                    String taxAmount, String clientId,
                    String year, String month,
                    String status, String reportSeq, String pendingPayment,
                    String inputDate,
                    String opercode) {
        this.setCan(can)
                .setSaleDate(saleDate)
                .setModelYear(modelYear)
                .setMake(make)
                .setVinNo(vinNo)
                .setSaleType(saleType)
                .setBuyerName(buyerName)
                .setSalesPrice(salesPrice)
                .setTaxAmount(taxAmount)
                .setClientId(clientId)
                .setYear(year)
                .setMonth(month)
                .setStatus(status)
                .setReportSeq(reportSeq)
                .setPendingPayment(pendingPayment)
                .setInputDate(inputDate)
                .setOpercode(opercode);

        return this;
    }

    public static SITSale initialContext(){
        return new SITSale();
    }

    public SITSale addSale(String datasource,
                            String username,
                            String password
                            ) throws Exception{
        try ( Connection conn = Connect.open(datasource, username, password);){
            return addSale(conn);
        }
    }

    public SITSale addSale(String datasource) throws  Exception{
        try (Connection conn = Connect.open(datasource);){
            return addSale(conn);
        }
    }
    public SITSale addSale(Connection conn) throws Exception{
        getSalesSeq(conn);
        getUptv(conn);
        try (
              PreparedStatement ps = conn.prepareStatement(
                                          " INSERT into sit_sales( "
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
                                        + "  VALUES (?,TO_DATE(?, 'mm/dd/yyyy'),?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,TO_DATE(?, 'mm/dd/yyyy'), UPPER(?) , CURRENT_TIMESTAMP) ");
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

        return this;
    }

    public SITSale updateSale(String datasource,
                                String username,
                                String password
                                ) throws Exception{
        try ( Connection conn = Connect.open(datasource, username, password);){
            return updateSale(conn);
        }
    }

    public SITSale updateSale(String datasource) throws  Exception{
        try ( Connection conn = Connect.open(datasource); ){
            return updateSale(conn);
        }
    }

    public SITSale updateSale(Connection conn) throws  Exception{
        try (
                PreparedStatement ps = conn.prepareStatement(
                                                "UPDATE sit_sales"
                                              + "  SET date_of_sale = TO_DATE(?, 'mm/dd/yyyy'),"
                                              + "        model_year = ?,"
                                              + "        make = ?,"
                                              + "        vin_serial_no = ?, "
                                              + "        sale_type = ?,"
                                              + "        purchaser_name = ?,"
                                              + "        sales_price = ?,"
                                              + "        tax_amount = ?,"
                                              + "        input_date = TO_DATE(?, 'mm/dd/yyyy'),"
                                              + "        chngdate = sysdate,"
                                              + "        opercode = decode(opercode,'LOAD','LOAD',UPPER(?))"
                                              + "  WHERE year = ?"
                                              + "        and month = ?"
                                              + "        and client_id = ?"
                                              + "        and can = ?"
                                              + "        and sales_seq = ?");

        ){
            ps.setString(1, saleDate);
            ps.setString(2, modelYear);
            ps.setString(3, make);
            ps.setString(4, vinNo);
            ps.setString(5, saleType);
            ps.setString(6, buyerName);
            ps.setString(7, salesPrice);
            ps.setString(8, taxAmount);
            ps.setString(9, inputDate);
            ps.setString(10, opercode);
            ps.setString(11, year);
            ps.setString(12, month);
            ps.setString(13, clientId);
            ps.setString(14, can);
            ps.setString(15, salesSeq);

            if ( !(ps.executeUpdate() >0 )) {
                throw  new Exception("Failed to update the sales record");
            }


        } catch (Exception e){
            throw e;
        }

        return this;
    }

    public SITSale removeSale(String datasource,
                                String username,
                                String password
                                ) throws  Exception{
        try ( Connection conn = Connect.open(datasource, username, password) ){
            return removeSale(conn);
        }
    }

    public  SITSale removeSale(String datasource)throws  Exception{
        try ( Connection conn = Connect.open(datasource) ) {
            return this.removeSale(conn);
        }
    }
    public SITSale removeSale(Connection conn) throws  Exception{
        try(
             PreparedStatement ps = conn.prepareStatement(
                                            " DELETE from sit_sales"
                                          + "  WHERE year = ?"
                                          + "   and month = ?"
                                          + "   and client_id = ?"
                                          + "   and can = ?"
                                          + "   and sales_seq =?");
        ){

            ps.setString(1, year);
            ps.setString(2, month);
            ps.setString(3, clientId);
            ps.setString(4, can);
            ps.setString(5, salesSeq);

            if ( !(ps.executeUpdate() > 0) ) {
                throw new Exception("Failed to delete the sales record");
            }

        } catch (Exception e){
            throw  e;
        }

        return  this;
    }

    public SITSale getSalesSeq(String datasource) throws  Exception{
        try (Connection conn = Connect.open(datasource);){
            return getSalesSeq(conn);
        }
    }

    public SITSale getSalesSeq(Connection conn) throws  Exception{
        try (
                PreparedStatement ps = conn.prepareStatement("SELECT sit_sales_seq.nextval FROM dual");

        ){
            ResultSet rs  = ps.executeQuery();
            if (!rs.isBeforeFirst()) throw  new Exception("Failed to retrieve the sales sequence");
            if ( rs.next() ) {
                this.salesSeq = rs.getString(1);
            }
        } catch (Exception e){
            throw e;
        }

        return this;
    }

    public SITSale getUptv(String datasource) throws  Exception {
        try (Connection conn = Connect.open( datasource );){
            return getUptv(conn);
        }
    }

    public SITSale getUptv(Connection conn) throws  Exception{
        try (
                PreparedStatement ps = conn.prepareStatement("SELECT act_subsystems.taxunit_monthly_rate(?,?,?) FROM DUAL")
        ){
            ps.setString(1, can);
            ps.setString(2, year);
            ps.setString(3, clientId);

            ResultSet rs = ps.executeQuery();
            if (!( rs.isBeforeFirst( ))) { throw  new Exception("Failed to retrieve the uptv"); }
            if (rs.next()) {
                this.uptv = rs.getString(1);
            }

        } catch (Exception e){
            throw e;
        }

        return this;
    }

    public SITSale  setDataSource(String dataSource){
        this.dataSource = dataSource;
        return this;
    }

    public SITSale  setClientId(String clientId){
        this.clientId = clientId;
        return this;
    }

    public SITSale setCan(String can){
        this.can = can;
        return this;
    }

    public SITSale setSaleDate(String saleDate){
        this.saleDate = saleDate;
        return this;
    }

    public SITSale setModelYear(String modelYear){
        this.modelYear = modelYear;
        return this;
    }

    public SITSale setMake(String make){
        this.make = make;
        return this;
    }

    public SITSale setVinNo(String vinNo){
        this.vinNo = vinNo;
        return this;
    }

    public SITSale setSaleType(String saleType){
        this.saleType = saleType;
        return this;
    }

    public SITSale setBuyerName(String buyerName){
        this.buyerName = buyerName;
        return this;
    }

    public SITSale setSalesPrice(String salesPrice){
        this.salesPrice = salesPrice;
        return this;
    }

    public SITSale setTaxAmount(String taxAmount){
        this.taxAmount = taxAmount;
        return this;
    }

    public SITSale setYear(String year){
        this.year = year;
        return  this;
    }

    public SITSale setMonth(String month){
        this.month = month;
        return this;
    }

    public SITSale setSalesSeq(String salesSeq){
        this.salesSeq = salesSeq;
        return this;
    }

    public SITSale setStatus(String status){
        this.status = status;
        return this;
    }

    public SITSale setReportSeq(String reportSeq){
        this.reportSeq = reportSeq;
        return this;
    }

    public SITSale setUptv(String uptv){
        this.uptv = uptv;
        return this;
    }

    public SITSale setPendingPayment(String pendingPayment){
        this.pendingPayment = pendingPayment;
        return this;
    }

    public SITSale setInputDate(String inputDate){
        this.inputDate = inputDate;
        return this;
    }

    public SITSale setOpercode(String opercode){
        this.opercode = opercode;
        return this;
    }

    public SITSale setChngDate(String chngDate){
        this.chngDate = chngDate;
        return this;
    }


    protected String      dataSource          = null;
    protected String      clientId            = null;
    protected String      can                 = null;
    public String      saleDate            = null;
    public String      modelYear           = null;
    public String      make                = null;
    public String      vinNo               = null;
    public String      saleType            = null;
    public String      buyerName           = null;
    public String      salesPrice          = null;
    public String      taxAmount           = null;
    public String      year                = null;
    public String      month               = null;
    public String      salesSeq            = null;
    public String      status              = null;
    public String      reportSeq           = null;
    public String      uptv                = null;
    public String      pendingPayment      = null;
    public String      inputDate           = null;
    public String      opercode            = null;
    public String      chngDate            = null;


}
