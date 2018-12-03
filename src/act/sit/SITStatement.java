package act.sit;

import java.io.File;
import java.io.FileInputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import act.util.*;
import com.sun.org.apache.xml.internal.resolver.readers.ExtendedXMLCatalogReader;

/**
 * Created by Duc.Nguyen on 11/28/2018.
 */
public class SITStatement {

    public static void main(String [] args ) throws Exception {
        try {
            Connection conn = Connect.open("jdbc:oracle:thin:@ares:1521/actd", "sit_inq", "texas1");
            SITStatement statement = initialContext();
            //statement.retrieveStatementInfo(conn,"7580","99B03507000000000","11","2018","1");
            //System.out.println(statement.status + " " + statement.keySeq + " " + statement.noteSeq );
            //statement.writeToSitDocuments(conn,true,"7580","Test","99B03507000000000","1","2018","11","59460","NOV 2018 SALES REPORT - WEB","MONRPT");
            //statement.verifyStatement(conn, "7580", "59460");
            //System.out.println(statement.statementExists + " " + statement.isStatementImageSaved);
            //statement.updateStatementStatus(conn, "7580", "test","99B03996000000000","05","2018","2");
            statement.writeToSitNotes(conn, "7580","99B03507000000000", "23777","Test 12/02/2018","DN");ds



        } catch (Exception e){ throw e ; }
    }

    public SITStatement(){}

    public SITStatement set(String dataSource,
                            String clientId,
                            String can,
                            String month,
                            String year,
                            String user,
                            String type,
                            String seq,
                            String description,
                            String preNote
                            ){
        this.setDataSource( dataSource )
                .setClientId( clientId )
                .setCan( can )
                .setMonth( month )
                .setYear( year )
                .setUser( user )
                .setStatementType( type )
                .setSeq( seq )
                .setDescription(description)
                .setPreNote(preNote);

        return this;
    }
    public static SITStatement initialContext(){
        return new SITStatement();
    }

    public SITStatement setDataSource(String dataSource ){
        this.dataSource = dataSource;
        return  this;
    }

    public SITStatement setClientId (String clientId ){
        this.clientId = clientId;
        return this;
    }

    public SITStatement setUser(String user ){
        this.user = user;
        return  this;
    }

    public SITStatement setStatementType(String type ) {
        this.statementType = type;
        return  this;
    }


    public SITStatement setStatus(String status ) {
        this.status = status;
        return this;
    }

    public SITStatement setSeq(String seq ) {
        this.seq = seq;
        return this;
    }

    public SITStatement setKeySeq(String keySeq ){
        this.keySeq = keySeq;
        return this;
    }

    public SITStatement setCan(String can ) {
        this.can = can;
        return this;
    }

    public SITStatement setMonth(String month ){
        this.month = month;
        return this;
    }

    public SITStatement setYear(String year ){
        this.year = year;
         return this;
    }

    public SITStatement setDescription(String description ){
        this.description = description;
        return this;
    }

    public SITStatement setPreNote(String preNote){
        this.preNote = preNote;
        return  this;
    }

    public SITStatement setFileName(String type, String keySeq, String fileTime){
        this.fileName = type + keySeq + "-" + fileTime +".pdf";
        return this;
    }

    public SITStatement setFilePath(String tempDir, String fileTime){
        this.filePath = tempDir + "SIT_" + fileTime + ".pdf";
        return this;
    }

    public SITStatement setFinalizeOnPay(boolean finalizeOnPay ){
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
    public      String   noteSeq               = null;
    public      String   description           = null;
    public      String   preNote               = null;

    public      String  fileName               = null;
    public      String  filePath               = null;

    protected   boolean  finalizeOnPay         = false;
    protected   boolean  isStatementImageSaved = false;
    protected   boolean  statementExists       = false;
    protected   String   dataSource            = null;


    public SITStatement retrieveStatementInfo() throws  Exception {
        return retrieveStatementInfo(dataSource, clientId, can, month, year, seq);
    }

    public SITStatement retrieveStatementInfo(String dataSource,
                                              String clientId,
                                              String can,
                                              String month,
                                              String year,
                                              String seq
                                                ) throws Exception {
        try ( Connection conn = Connect.open(dataSource) ){
            return  retrieveStatementInfo(conn, clientId, can, month, year, seq);
        } catch (Exception e){
            throw  e;
        }

    }

    public SITStatement retrieveStatementInfo(Connection conn,
                                              String clientId,
                                              String can,
                                              String month,
                                              String year,
                                              String seq
                                                ) throws  Exception{
        try ( PreparedStatement ps = conn.prepareStatement(
                                            " with statement(clientId, can, month, year, seq ) as (select ?,?,?,?,? from dual)"
                                                    + " select coalesce("
                                                    + "                 (select key_seq from sit_documents"
                                                    + "                     where client_id = statement.clientId"
                                                    + "                             and key_id  = statement.can"
                                                    + "                             and key_year = statement.year"
                                                    + "                             and reference_no = statement.month"
                                                    + "                             and event_seq = statement.seq)"
                                                    + "                 ,document_seq.nextval) as keySeq"
                                                    + " , notes_seq.nextval noteSeq, master.report_status"
                                                    + " from statement"
                                                    + "  join sit_sales_master master"
                                                    + "    on (master.client_id = statement.clientId"
                                                    + "        and master.can = statement.can"
                                                    + "        and master.month = statement.month"
                                                    + "        and master.year = statement.year"
                                                    + "        and master.report_seq = statement.seq)"
                                                        );){
            ps.setString(1, clientId);
            ps.setString(2, can);
            ps.setString(3, month);
            ps.setString(4, year);
            ps.setString(5, seq);

            try (ResultSet rs = ps.executeQuery() ){
                if ( !rs.isBeforeFirst() ) throw new Exception("Unable to retrieve the key sequence, note sequence, and statement status for this account with report sequence "+ seq);
                if (rs.next() ){
                    status  = rs.getString("report_status");
                    keySeq  = rs.getString("keySeq");
                    noteSeq = rs.getString("noteSeq");
                }
            } catch (Exception e){
                throw e;
            }


        } catch (Exception e){
            throw  e;
        }

        return this;

    }

    public SITStatement writeToSitDocuments() throws  Exception{
        return writeToSitDocuments(dataSource, statementExists, clientId, user, can, seq, year, month, keySeq, description, statementType);
    }

    public SITStatement writeToSitDocuments(String dataSource,
                                            boolean statementExists,
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
            return writeToSitDocuments(conn, statementExists, clientId, user, can, seq, year, month, keySeq, description, statementType);
        } catch (Exception e){
            throw e;
        }
    }

    public SITStatement writeToSitDocuments(Connection conn,
                                            boolean statementExists,
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
       if ( statementExists ) {
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
                   throw  new Exception("Unable to update the existing statement record in sit_documents table");
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
                                                            );) {
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

               if ( !(ps.executeUpdate() > 0) ){
                   throw  new Exception("Unable to add the statement record into sit_documents table");
               }

           }
       }

        return this;
    }

    public SITStatement writeToSitDocumentImages() throws Exception {
        return writeToSitDocumentImages(dataSource, isStatementImageSaved, clientId, user, fileName, filePath, keySeq);

    }

    public SITStatement writeToSitDocumentImages(String dataSource,
                                                 boolean isStatementImageSaved,
                                                 String clientId,
                                                 String user,
                                                 String fileName,
                                                 String filePath,
                                                 String keySeq
                                                 ) throws Exception{
        try ( Connection conn = Connect.open(dataSource); ){
            return writeToSitDocumentImages(conn, isStatementImageSaved, clientId, user, fileName, filePath, keySeq);
        } catch (Exception e){
            throw  e;
        }

    }

    public SITStatement writeToSitDocumentImages(Connection conn,
                                                 boolean isStatementImageSaved,
                                                 String clientId,
                                                 String user,
                                                 String fileName,
                                                 String filePath,
                                                 String keySeq
                                                ) throws Exception {
        java.io.File file = new File(filePath);
        if ( !file.exists() ) throw new Exception("The file is not available to insert into sit_document_images table");
        FileInputStream fileInput = new FileInputStream(file);
        if ( isStatementImageSaved ){
            try (PreparedStatement ps = conn.prepareStatement(
                                                    "update sit_document_images"
                                                  + "   set file_blob=?,"
                                                  + "       file_name=?,"
                                                  + "       opercode=decode(opercode,'LOAD','LOAD',UPPER(?)),"
                                                  + "       chngdate=sysdate"
                                                  + " where client_id=?"
                                                  + "       and key_seq=?"
                                                            );) {
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
                                                                );) {
                ps.setString(1, clientId);
                ps.setString(2, keySeq);
                ps.setBinaryStream(3, fileInput, (int) file.length());
                ps.setString(4, fileName);
                ps.setInt(5,0);
                ps.setString(6, user);

                if (!(ps.executeUpdate()>0)) throw  new Exception("Unable to add the statement image into sit_document_images table");
            } catch (Exception e){
                throw  e;
            }
        }

        return this;

    }

    public SITStatement writeToSitNote() throws  Exception {
        return writeToSitNote(dataSource, clientId,  can, noteSeq, preNote, user);
    }

    public SITStatement writeToSitNote(String dataSource,
                                       String  clientId,
                                       String can,
                                       String noteSeq,
                                       String preNote,
                                       String user
                                       ) throws  Exception {
        try( Connection conn = Connect.open(dataSource); ){
            return writeToSitNotes(conn, clientId, can, noteSeq, preNote, user);

        } catch (Exception e){
            throw e;
        }
    }

    public SITStatement writeToSitNotes(Connection conn,
                                        String clientId,
                                        String can,
                                        String noteSeq,
                                        String preNote,
                                        String user
                                        ) throws  Exception {
        try ( PreparedStatement ps = conn.prepareStatement(
                                            "INSERT INTO notes ("
                                               + "   client_id,"
                                               + "   can,"
                                               + "   noteseq,"
                                               + "   notexdte,"
                                               + "   note,"
                                               + "   msgcode,"
                                               + "   opercode,"
                                               + "   chngdate) "
                                               + "VALUES (?,?,?,  sysdate, ? || TO_CHAR(sysdate, 'MM/DD/YYYY'), ?, UPPER(?), sysdate)"
                                                        );){
            ps.setString(1, clientId);
            ps.setString(2, can);
            ps.setString(3, noteSeq);
            ps.setString(4, preNote);
            ps.setString(5, "MSG");
            ps.setString(6, "WEB-" + user);

            if ( !(ps.executeUpdate()>0) ) throw  new Exception("Unable to add the note into note table");

        } catch (Exception e){
            throw  e;
        }
        return this;
    }

    public SITStatement verifyStatement() throws Exception {
        return verifyStatement(dataSource, clientId, keySeq);
    }

    public SITStatement verifyStatement(String dataSource,
                                        String clientId,
                                        String keySeq
                                        ) throws  Exception{
        try( Connection conn = Connect.open(dataSource); ){
            return verifyStatement(conn, clientId, keySeq);

        } catch (Exception e){
            throw e;
        }
    }

    public SITStatement verifyStatement(Connection conn,
                                        String clientId,
                                        String keySeq
                                        ) throws Exception{
        try ( PreparedStatement ps = conn.prepareStatement(
                                             " with record( clientId, keySeq ) as (select ?, ? from dual)"
                                                + "         select  (select count(*)"
                                                + "                     from sit_documents"
                                                + "                     where client_id = record.clientId"
                                                + "                             and key_seq = record.keySeq"
                                                + "                     group by key_seq) documents,"
                                                + "                 (select count(*)"
                                                + "                     from sit_document_images"
                                                + "                     where client_id = record.clientId"
                                                + "                             and key_seq = record.keySeq"
                                                + "                     group by key_seq) images from record"
                                                        );) {
            ps.setString(1, clientId);
            ps.setString(2, keySeq);

            try ( ResultSet rs = ps.executeQuery() ){
                if (!rs.isBeforeFirst() ) throw new Exception("Unable to verify the statement");
                if ( rs.next() ) {
                    statementExists         = rs.getInt("documents") > 0;
                    isStatementImageSaved   = rs.getInt("images") > 0;
                }
            } catch (Exception e){
                throw  e;
            }

        } catch (Exception e){
            throw  e;
        }

        return this;

    }

    public SITStatement updateStatementStatus() throws  Exception {
        return updateStatementStatus(dataSource, clientId, user, can, month, year, seq);
    }

    public SITStatement updateStatementStatus(String dataSource,
                                              String clientId,
                                              String user,
                                              String can,
                                              String month,
                                              String year,
                                              String seq
                                              ) throws  Exception {
        try ( Connection conn = Connect.open(dataSource); ){
            return updateStatementStatus(conn, clientId, user, can, month, year, seq);
        } catch (Exception e){
            throw  e;
        }

    }

    public SITStatement updateStatementStatus(Connection conn,
                                              String clientId,
                                              String user,
                                              String can,
                                              String month,
                                              String year,
                                              String seq
                                              ) throws  Exception {
        try ( PreparedStatement ps = conn.prepareStatement(
                                            "update sit_sales_master"
                                               + " set report_status = 'C',"
                                               + "       opercode = decode(opercode,'LOAD','LOAD',UPPER(?)),"
                                               + "       chngdate= sysdate,"
                                               + "       finalize_date=CURRENT_TIMESTAMP "
                                               + " where client_id=?"
                                               + "       and can=?"
                                               + "       and month=?"
                                               + "       and year=?"
                                               + "       and report_seq=?"
                                                            );) {
            ps.setString(1, user);
            ps.setString(2, clientId);
            ps.setString(3, can);
            ps.setString(4, month);
            ps.setString(5, year);
            ps.setString(6, seq);

            if (!(ps.executeUpdate() >0 )) throw new Exception("Unable to update the statement status");


        } catch (Exception e){
            throw e;
        }

        return this;

    }

}
