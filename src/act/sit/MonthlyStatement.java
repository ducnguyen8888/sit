package act.sit;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import act.util.*;

/**
 * Created by Duc.Nguyen on 11/28/2018.
 */
public class MonthlyStatement extends SITStatement {

    public static void main(String [] args) throws  Exception{
            MonthlyStatement monthlyStatement = new MonthlyStatement();
            try {
                Connection conn = Connect.open("jdbc:oracle:thin:@ares:1521/actd", "sit_inq", "texas1");
                monthlyStatement.retrieveAmountDueByMonth(conn, "7580", "99B03507000000000", "09", "2018");
                System.out.println(monthlyStatement.fakharTotal+ " " + monthlyStatement.fakharMin);
            } catch (Exception e){
                throw  e;
            }

    }
    public MonthlyStatement(){ }

    public MonthlyStatement setPayments(Payments payments){
        this.payments = payments;
        return this;
    }

    protected String    fakharTotal    = null;
    protected double    fakharMin      = 0.0;
    protected Payments  payments       = null;


    public static String months []        = { null , "JAN" , "FEB" , "MAR" , "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" };
    public static String [] monthsText    = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};

    public MonthlyStatement retrieveAmountDueByMonth() throws Exception{
        return retrieveAmountDueByMonth(dataSource, clientId, can, month, year);
    }
    public MonthlyStatement retrieveAmountDueByMonth(String dataSource,
                                                     String clientId,
                                                     String can,
                                                     String month,
                                                     String year
                                                    ) throws  Exception {
        try ( Connection conn = Connect.open(dataSource ) ){
            return retrieveAmountDueByMonth(conn, clientId, can, month, year);
        } catch (Exception e){
            throw  e;
        }
    }
    public MonthlyStatement retrieveAmountDueByMonth(Connection conn,
                                                     String clientId,
                                                     String can,
                                                     String month,
                                                     String year
                                                    ) throws  Exception {
        try (CallableStatement cs = conn.prepareCall(
                                                "{ ?=call vit_utilities.get_amount_due_by_month(?,?,?,?) }");){
            cs.registerOutParameter(1, oracle.jdbc.OracleTypes.CURSOR);
            cs.setString(2, clientId);
            cs.setString(3, can);
            cs.setString(4, year);
            cs.setString(5, month);
            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(1)){
                if ( ! rs.isBeforeFirst() ) { fakharTotal = "0.00";};
                if ( rs.next() ){
                    fakharMin   = rs.getDouble("msale_levybal") + rs.getDouble("msale_penbal");
                    fakharTotal = rs.getString("AMOUNT_DUE");
                }

            } catch (Exception e){
                throw  e;
            }

        } catch (Exception e){
            throw e;
        }
        return this;
    }

    public MonthlyStatement addToCart() throws  Exception {
        return addToCart(payments);
    }

    public MonthlyStatement addToCart(Payments payments) throws  Exception{
        return addToCart(payments, can, month, year, seq );
    }

    public MonthlyStatement addToCart(Payments payments,
                                      String can,
                                      String month,
                                      String year,
                                      String seq) throws Exception {

        try {
            String description = (monthsText[Integer.parseInt(month)] + " " + year);
            if (!"0.00".equals(fakharTotal)) {
                payments.add(new Payment(can, seq, year, month, description, fakharTotal, "0.0", fakharTotal, String.valueOf(fakharMin), "0.00"));
            }
        } catch ( Exception e ){
            throw e;
        }
        return this;
    }



    public MonthlyStatement closeStatement() throws  Exception {
        try {
            PDFConverter.convertToPdf("/usr/bin/chmod 666 ",tempDir, fileName, htmlContent, pdfConverterUrl);
            retrieveStatementInfo();
            verifyStatement();

            if ( !"C".equals( status ) ){
                writeToSitDocumentImages();
                writeToSitDocuments();

                if ( finalizeOnPay
                        || "2000".equals( clientId ) ) {
                    retrieveAmountDueByMonth();
                    addToCart();
                }

                if ( !finalizeOnPay
                        || Double.parseDouble(fakharTotal) == 0 ){
                    updateStatementStatus();
                }

                writeToSitNote();
            }

        } catch (Exception e) {
            throw  e;
        }

        return  this;
    }

}
