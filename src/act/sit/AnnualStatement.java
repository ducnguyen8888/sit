package act.sit;

import act.util.Connect;
import act.util.PDFConverter;

import java.sql.Connection;
import java.sql.PreparedStatement;

/**
 * Created by Duc.Nguyen on 11/28/2018.
 */
public class AnnualStatement extends SITStatement {

    public static void main(String [] args) throws Exception{
        AnnualStatement annualStatement = new AnnualStatement();
        try {
            String month = "13";
            String year = "2017";
            String description = year +  " ANNUAL REPORT - WEB";
            String preNote = "Yearly Sales Report for %d (%s Sales) finalized on ";;
            Payments payments = new Payments();
                annualStatement.set("jdbc:oracle:thin:@ares:1521/actd","7580",
                                    "99B03507000000000",month,year,"DN","ANNDEC","1",description,preNote,"11282018154532",
                                    "C:/Users/Duc.Nguyen/IdeaProjects/sit/out/artifacts/sit_war_exploded/temp/","Hello SIT 12.07.2018",
                                    "http://localhost:4430","Test","duc.nguyen@lgbs.com","duc.nguyen@lgbs.com","123","test","Test","1234567890");
                annualStatement.setImportedRecords(true)
                        .setMonthlyFormType("50-260")
                        .setSalesInfo("9","8","7","6","","9000","8000","7000","","6000")
                        .closeStatement();
        } catch (Exception e ){
            throw  e;
        }
    }

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

    public AnnualStatement setImportedRecords(boolean importedRecords){
        this.importedRecords = importedRecords;
        return this;
    }

    public AnnualStatement setMonthlyFormType(String type) {
        this.monthlyFormType = type;
        return  this;
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

    public String   formAnnual               = null;
    public String   dealerType               = null;
    public String   monthlyFormType          = null;


    public String [][] formDealerTypes       = new String [][]{
                                                                {"50-246","50_244","1"},//1 motor vehicle
                                                                {"50-260","50_259","2"},//2 outboard
                                                                {"50-266","50_265","3"},//3 heavy equipment
                                                                {"50-268","50_267","4"}//4 housing
                                                              };


    public AnnualStatement retrieveFormDealerType(){
        return retrieveFormDealerType(monthlyFormType);
    }
    public AnnualStatement retrieveFormDealerType(String type ){
        for ( String[] formDealerType : formDealerTypes ){
            if( type.equals(formDealerType[0])){
                formAnnual = formDealerType[1];
                dealerType = formDealerType[2];
            }
        }

        return this;
    }

    public AnnualStatement updateStatementStatus(String dataSource,
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
                                                 ) throws  Exception {
        try(Connection conn = Connect.open(dataSource)){
            updateStatementStatus(conn, clientId, can, year, user,
                                    inventorySaleUnits, fleetSaleUnits, dealerSaleUnits, subsequentSaleUnits, retailSaleUnits,
                                    inventorySaleAmount, fleetSaleAmount, dealerSaleAmount, subsequentSaleAmount, retailSaleAmount);
         } catch (Exception e){
            throw e;
        }

        return this;
    }
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

    public AnnualStatement writeToSitSalesMaster() throws  Exception{
        return writeToSitSalesMaster(dataSource, clientId, can, year, seq, dealerType, formAnnual, user );
    }
    public AnnualStatement writeToSitSalesMaster(String dataSource,
                                                 String clientId,
                                                 String can,
                                                 String year,
                                                 String seq,
                                                 String dealerType,
                                                 String formAnnual,
                                                 String user
                                                 ) throws Exception {
        try(Connection conn = Connect.open(dataSource);){
            return writeToSitSalesMaster(conn, clientId, can, year, seq, dealerType, formAnnual, user);
        } catch (Exception e){
            throw e;
        }

    }

    public AnnualStatement writeToSitSalesMaster(Connection conn,
                                                 String clientId,
                                                 String can,
                                                 String year,
                                                 String seq,
                                                 String dealerType,
                                                 String formAnnual,
                                                 String user
                                                ) throws  Exception {
        try (PreparedStatement ps = conn.prepareStatement(
                                                "insert into sit_sales_master "
                                              + "   (client_id,"
                                              + "   can,"
                                              + "   year,"
                                              + "   month,"
                                              + "   report_seq,"
                                              + "   report_status,"
                                              + "   dealer_type,"
                                              + "   form_name,"
                                              + "   pending_payment,"
                                              + "   opercode,"
                                              + "   chngdate) "
                                              + "VALUES (?, ?, ?, ?, ?, 'O', ?, ?, 'N', ?, sysdate) "
                                                        );){
            ps.setString(1, clientId);
            ps.setString(2, can);
            ps.setString(3, year);
            ps.setInt(4, 13);
            ps.setString(5, seq);
            ps.setString(6, dealerType);
            ps.setString(7, formAnnual);
            ps.setString(8, user);

            if (!(ps.executeUpdate() > 0 )) throw new Exception("Unable to insert the record into sit_sales_master table");
        }
        return this;
    }
    public AnnualStatement closeStatement() throws Exception{
        try {
            retrieveFormDealerType();
            PDFConverter.convertToPdf(rootPath, tempDir, fileTime, htmlContent, pdfConverterUrl);
            retrieveStatementInfo();
            verifyStatement();

            if( !statementExists ) {
                writeToSitDocumentImages();
            }

            if ( !"C".equals(status )) {
                writeToSitDocumentImages();
                writeToSitDocuments();
                if( importedRecords ) {
                    updateStatementStatus(dataSource, clientId, can, year, user,
                                            inventorySaleUnits, fleetSaleUnits, dealerSaleUnits, subsequentSaleUnits, retailSaleUnits,
                                            inventorySaleAmount, fleetSaleAmount, dealerSaleAmount, subsequentSaleAmount, retailSaleAmount);
                } else {
                    updateStatementStatus();
                }

                writeToSitNotes();
                sendConfirmationEmail();
            }
        } catch (Exception e){
            throw e;
        }
        return this;
    }
}
