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
        SITStatement monthlyStatement = new MonthlyStatement();
        try {
            String month = "08";
            String year = "2018";
            String description = MonthlyStatement.months[Integer.parseInt("08")] + " " + "2018" + " SALES REPORT - WEB";
            String preNote = "Monthly Sales Report for "+ month +"/"+ year +" finalized on ";
            Payments payments = new Payments();
            monthlyStatement.set("jdbc:oracle:thin:@ares:1521/actd","7580",
                    "99B03996000000000",month,year,"DN","MONRPT","1",description,preNote,"11282018154532",
                    "C:/Users/Duc.Nguyen/IdeaProjects/sit/out/artifacts/sit_war_exploded/temp/","Hello SIT 12.04.2018",
                    "http://localhost:4430","Test","duc.nguyen@lgbs.com","duc.nguyen@lgbs.com","123","test","Test","1234567890")
                    .setPayments(payments)
                    .setFinalizeOnPay(true)
                    .closeStatement();

            System.out.println(payments.payments.get(0).amountDue);

        } catch (Exception e){
            throw e;
        }

    }

    public MonthlyStatement(){ }

    protected String    fakharTotal    = null;
    protected double    fakharMin      = 0.0;

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
            PDFConverter.convertToPdf(rootPath, tempDir, fileTime, htmlContent, pdfConverterUrl);
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

                writeToSitNotes();
            }

        } catch (Exception e) {
            throw  e;
        }

        return  this;
    }

}
