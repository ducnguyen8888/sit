package act.sit;

import java.io.File;
import java.io.FileInputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import act.util.*;

/**
 * Created by Duc.Nguyen on 11/28/2018.
 */
public class Statement {

    public static void main(String [] args ) {
        try {
            Connection conn = Connect.open("jdbc:oracle:thin:@ares:1521/actd", "sit_inq", "texas1");
            Statement statement = initialContext();
            statement.retrieveStatementInfo(conn,"7580","99P13409000000000","09","2018","1");
            System.out.println( statement.status + " " + statement.keySeq);
        } catch (Exception e){}
    }

    public Statement(){}

    public Statement set(String dataSource,
                            String clientId,
                            String can,
                            String month,
                            String year,
                            String user,
                            String type,
                            String seq,
                            String description){
        this.setDataSource( dataSource )
                .setClientId( clientId )
                .setCan( can )
                .setMonth( month )
                .setYear( year )
                .setUser( user )
                .setStatementType( type )
                .setSeq( seq )
                .setDescription(description);
        return this;
    }
    public static Statement initialContext(){
        return new Statement();
    }

    public Statement setDataSource( String dataSource ){
        this.dataSource = dataSource;
        return  this;
    }

    public Statement setClientId ( String clientId ){
        this.clientId = clientId;
        return this;
    }

    public Statement setUser( String user ){
        this.user = user;
        return  this;
    }

    public Statement setStatementType( String type ) {
        this.statementType = type;
        return  this;
    }


    public Statement setStatus( String status ) {
        this.status = status;
        return this;
    }

    public Statement setSeq( String seq ) {
        this.seq = seq;
        return this;
    }

    public  Statement setKeySeq( String keySeq ){
        this.keySeq = keySeq;
        return this;
    }

    public Statement setCan( String can ) {
        this.can = can;
        return this;
    }

    public Statement setMonth( String month ){
        this.month = month;
        return this;
    }

    public Statement setYear( String year ){
        this.year = year;
         return this;
    }

    public Statement setDescription( String description ){
        this.description = description;
        return this;
    }

    public Statement setFileName(String type, String keySeq, String fileTime){
        this.fileName = type + keySeq + "-" + fileTime +".pdf";
        return this;
    }

    public Statement setFilePath(String tempDir, String fileTime){
        this.filePath = tempDir + "SIT_" + fileTime + ".pdf";
        return this;
    }

    public Statement setFinalizeOnPay( boolean finalizeOnPay ){
        this.finalizeOnPay = finalizeOnPay;
        return this;
    }


    public      String   clientId              = null;
    public      String   user                  = null;
    public      String   statementType         = null;
    public      String   status                = null;
    public      String   can                   = null;
    public      String   month                 = null;
    public      String   year                  = null;
    public      String   seq                   = null;
    public      String   keySeq                = null;
    public      String   description           = null;

    public      String  fileName               = null;
    public      String  filePath               = null;

    protected   boolean  finalizeOnPay         = false;
    protected   boolean  isStatementSaved      = false;
    protected   String   dataSource            = null;


    public Statement retrieveStatementInfo() throws  Exception {
        return retrieveStatementInfo(dataSource, clientId, can, month, year, seq);
    }

    public Statement retrieveStatementInfo( String dataSource,
                                                String clientId,
                                                String can,
                                                String month,
                                                String year,
                                                String seq
                                                ) throws Exception {
        try (Connection conn = Connect.open(dataSource) ){
            return  retrieveStatementInfo(conn, clientId, can, month, year, seq);
        } catch (Exception e){
            throw  e;
        }

    }

    public Statement retrieveStatementInfo(Connection conn,
                                                String clientId,
                                                String can,
                                                String month,
                                                String year,
                                                String seq
                                                ) throws  Exception{
        try (PreparedStatement ps = conn.prepareStatement(
                                            " with statement(clientId, can, month, year, seq ) as (select ?,?,?,?,? from dual)"
                                                    + " select coalesce("
                                                    + "                 (select key_seq from sit_documents"
                                                    + "                     where client_id = statement.clientId"
                                                    + "                             and key_id  = statement.can"
                                                    + "                             and key_year = statement.year"
                                                    + "                             and reference_no = statement.month)"
                                                    + "                 ,document_seq.nextval) as keySeq"
                                                    + " , master.report_status"
                                                    + "from statement"
                                                    + "  join sit_sales_master master"
                                                    + "    on (master.client_id = statement.clientId"
                                                    + "        and master.can = statement.can"
                                                    + "        and master.month = statement.month"
                                                    + "        and master.year = statement.year"
                                                    + "        and master.report_seq = statement.seq)");){
            ps.setString(1, clientId);
            ps.setString(2, can);
            ps.setString(3, month);
            ps.setString(4, year);
            ps.setString(5, seq);

            try (ResultSet rs = ps.executeQuery() ){
                if ( !rs.isBeforeFirst() ) throw new Exception("Unable to retrieve the report status and key sequence for this account with report sequence "+ seq);
                if (rs.next() ){
                    status = rs.getString("report_status");
                    keySeq = rs.getString("keySeq");
                }
            } catch (Exception e){
                throw e;
            }


        } catch (Exception e){
            throw  e;
        }

        return this;

    }
    public Statement writeToSitDocuments() throws  Exception{
        return writeToSitDocuments(dataSource, isStatementSaved, clientId, user, can, seq, year, month, keySeq, description, statementType);
    }
    public Statement writeToSitDocuments( String dataSource,
                                             boolean isStatementSaved,
                                             String clientId,
                                             String user,
                                             String can,
                                             String seq,
                                             String year,
                                             String month,
                                             String keySeq,
                                             String description,
                                             String statementType
                                             ) throws  Exception {
        try ( Connection conn = Connect.open(dataSource); ){
            return writeToSitDocuments(conn, isStatementSaved, clientId, user, can, seq, year, month, keySeq, description, statementType);
        } catch (Exception e){
            throw e;
        }
    }

    public Statement writeToSitDocuments( Connection conn,
                                            boolean isStatementSaved,
                                            String clientId,
                                            String user,
                                            String can,
                                            String seq,
                                            String year,
                                            String month,
                                            String keySeq,
                                            String description,
                                            String statementType
                                            ) throws  Exception{
       if ( isStatementSaved ) {
           try ( PreparedStatement ps = conn.prepareStatement (
                                                    "update sit_documents"
                                                  + " set comments='FINALIZED: ' || sysdate,"
                                                  + "     opercode = decode(opercode,'LOAD','LOAD',UPPER(?)), "
                                                  + "     chngdate = sysdate "
                                                  + " where client_id=?"
                                                  + "         and key_id=?"
                                                  + "         and event_seq=?"
                                                  + "         and  key_year=?"
                                                  + "         and reference_no=?"
                                                  + "         and key_seq=?"
                                                                );) {
               ps.setString(1, user);
               ps.setString(2, clientId);
               ps.setString(3, can);
               ps.setString(4, seq);
               ps.setString(5, year);
               ps.setString(6, month);
               ps.setString(7, keySeq);

               if (!(ps.executeUpdate()>0)){
                   throw  new Exception("Failed to update the existing statement record in sit_documents table");
               }

           } catch (Exception e){
               throw e;
           }
       } else {
           try (PreparedStatement ps = conn.prepareStatement(
                                                    "insert into sit_documents "
                                                  + "(client_id,"
                                                  + " comments,"
                                                  + " description,"
                                                  + " document_type,"
                                                  + " event_seq,"
                                                  + " key_id,"
                                                  + " key_seq,"
                                                  + " key_type,"
                                                  + " key_year,"
                                                  + " reference_no,"
                                                  + " opercode)"
                                                  + " VALUES "
                                                  + "(?,'FINALIZED: ' || sysdate,?,?,?,?,?,?,?,?,UPPER(?))"
                                                            );){
               ps.setString(1, clientId);
               ps.setString(2, description);
               ps.setString(3, statementType);
               ps.setString(4, seq);
               ps.setString(5, can);
               ps.setString(6, keySeq);
               ps.setString(7, "A");
               ps.setString(8, year);
               ps.setString(9, month);
               ps.setString(10, user);

               if (!(ps.executeUpdate() > 0)){
                   throw  new Exception("Failed to add the statement record into sit_documents table");
               }

           }
       }

        return this;
    }

    public Statement writeToSitDocumentImages( Connection conn,
                                                boolean isStatementSaved,
                                                String clientId,
                                                String user,
                                                String fileName,
                                                String filePath,
                                                String keySeq
                                                ) throws Exception {
        java.io.File file = new File(filePath);
        if (!file.exists()) throw new Exception("This file is not available to insert into sit_document_images table");
        FileInputStream fileInput = new FileInputStream(file);
        if ( isStatementSaved ){
            try (PreparedStatement ps = conn.prepareStatement(
                                                    "update sit_document_images"
                                                  + "   set file_blob=?,"
                                                  + "       file_name=?,"
                                                  + "       opercode=decode(opercode,'LOAD','LOAD',UPPER(?)),"
                                                  + "       chngdate=sysdate"
                                                  + " where client_id=?"
                                                  + "       and key_seq=?"
                                                            );){
                ps.setBinaryStream(1, fileInput, (int) file.length());
                ps.setString(2, fileName);
                ps.setString(3, user);
                ps.setString(4, clientId);
                ps.setString(5, keySeq);

                if (!(ps.executeUpdate()>0)) throw  new Exception("Unable to update the existing statement image in sit_document_images table");
            } catch (Exception e){
                throw e;
            }
        } else {
            try ( PreparedStatement ps = conn.prepareStatement(
                                                    " insert into sit_document_images ("
                                                  + "   client_id,"
                                                  + "   key_seq,"
                                                  + "   file_blob,"
                                                  + "   file_name,"
                                                  + "   access_count,"
                                                  + "   opercode)"
                                                  + " VALUES (?,?,?,?,?,UPPER(?))"
                                                            );){
                ps.setString(1, clientId);
                ps.setString(2, keySeq);
                ps.setBinaryStream(3, fileInput, (int) file.length());
                ps.setInt(5,0);
                ps.setString(6, user);

                if (!(ps.executeUpdate()>0)) throw  new Exception("Unable to add the statement image into sit_document_images table");
            } catch (Exception e){
                throw  e;
            }
        }

        return this;

    }

}
