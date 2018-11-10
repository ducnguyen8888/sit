<%--
    DN - 1/10/2018 - PRC 195487 
        Added the function to check if the document image record is saved into sit_document_images table
        Updated the logic. We only update the document image record in  sit_document_images table if document exists and the document image record is saved. If not, we have to add a new one into sit_document_images table
    DN - 05/16/2018 - PRC 194431
        Harris County wants the "Go to Cart" button to be displayed after the form is finalized even though Harris County is not "Finalized on Pay"
    DN - 08/07/2018 - PRC 198588
        Moved getClientPref and getSitClientPref function to "_configuation.inc" file
    DN - 08/07/2018 - PRC 198408
        -Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
    DN - 11/05/2018 - PRC 209149
        Use client prefs JUR_ADDRESS1, JUR_ADDRESS2, JUR_ADDRESS4, JUR_EMAIL_ADDRESS, JUR_PHONE1 to control the tax office information in the confirmation email
--%><%

  java.text.DateFormat dateFormat = new java.text.SimpleDateFormat("MMddyyyyHHmmss");
  java.util.Calendar cal = java.util.Calendar.getInstance();
  String file_time = dateFormat.format(cal.getTime()); //a-key_seq-timestamp
  StringBuffer ts = new StringBuffer();
  StringBuffer contactInfo = new StringBuffer();
  boolean documentExists = false;
  boolean imageSaved   = false;
  
  SITUser    sitUser    = sitAccount.getUser();

  
  can = request.getParameter("can");
  year = request.getParameter("year");
  month = request.getParameter("month");
  month = month.length() == 1 ? "0" + month : month; // makes 7 = 07

  String months [] = { null , "JAN" , "FEB" , "MAR" , "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" };
  String description = months[Integer.parseInt(month)] + " " + year + " SALES REPORT - WEB";
  String report_status = "";
  int key_seq = 0; // sit_documents
  String fakharTotal = "";
  double fakharMin = 0.0;
  Connection connection = null;
  PreparedStatement ps = null;
  ResultSet rs = null;

  connection = connect();


  try{
        /* **************** Write initial temp html file ********************* */
        BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(tempDirectory + "SIT_"+file_time+".html"), "UTF-8"));
        try {
            bw.write(start.toString() +  end.toString());
        } finally {
            bw.close();
        }
        //Runtime.getRuntime().exec("/usr/bin/chmod 666" + tempDirectory + "SIT_"+file_time+".html" );
        /* **************** Send file info to PHP page ********************* */
        String USER_AGENT = "Mozilla/5.0";
        //String url2 = "http://apollo/mpdf/examples/jasonTest.php";
        java.net.URL obj = new java.net.URL(pdfConverterURL);
        java.net.HttpURLConnection con = (java.net.HttpURLConnection) obj.openConnection();
        ts.append("file name is " + tempDirectory + "SIT_"+file_time+".html\r\n");
        ts.append("pdfConverterURL is " + pdfConverterURL + "\r\n");
        //add reuqest header
        con.setRequestMethod("POST");
        con.setRequestProperty("User-Agent", USER_AGENT);
        con.setRequestProperty("Accept-Language", "en-US,en;q=0.5");
        String urlParameters = "file=SIT_"+file_time;
        // Send post request
        con.setDoOutput(true);
        DataOutputStream wr = new DataOutputStream(con.getOutputStream());
        wr.writeBytes(urlParameters);
        wr.flush();
        wr.close();
        int responseCode = con.getResponseCode();
  } catch(Exception e){SITLog.error(e, "\r\nProblem doing html/pdf conversion for " + thisPage + " in _monthly.jsp\r\n");}

  try{  // big outer try

      try{ // get report_seq and status
          ps = connection.prepareStatement(
                                "select report_status"
                               +"   from sit_sales_master "
                               +" where client_id=?"
                               +"       and can=?"
                               +"       and month=?"
                               +"       and year=?"
                               +"       and report_seq = ?");
                               
          ps.setString(1, client_id);
          ps.setString(2, can);// /request.getParameter("pw")
          ps.setString(3, month);
          ps.setString(4, year);
          ps.setString(5, report_sequence);
          rs = ps.executeQuery();
          if(rs.next()){
            report_status = rs.getString(1);
          } else {
            SITLog.info("no records found while searching for report_sequence and report_status");
            SITLog.info("_monthly: Getting report status: client_id: " + client_id + ", request.getParameter(\"can\"): " + request.getParameter("can") + ", month: " + month + ", request.getParameter(\"year\"): " + request.getParameter("year") + ", report_sequence : " + report_sequence );
          }
      } catch (Exception e) {
           SITLog.error(e, "\r\nProblem getting report info for " + thisPage + " in _monthly.jsp\r\n");
      } finally {
          try { rs.close(); } catch (Exception e) {  SITLog.error(e, "\r\nProblem closing rs for " + thisPage + " in _monthly.jsp\r\n"); }
          rs = null;
          try { ps.close(); } catch (Exception e) {  SITLog.error(e, "\r\nProblem closing ps for " + thisPage + " in _monthly.jsp\r\n"); }
          ps = null;
      }// try get report_seq and status
      
      if (! "C".equals(report_status) ){

        //TODO: if client_pref, then check if report exists
        //      if so, I update
        //      if not, I insert
        if(finalize_on_pay){
            try{ // check if report exists
                ps = connection.prepareStatement(
                                    "select key_seq"
                                   +"   from sit_documents"
                                   +" where client_id=?"
                                   +"       and event_seq=?"
                                   +"       and key_id=?"
                                   +"       and key_year=?"
                                   +"       and reference_no=?");
                                   
                ps.setString(1, client_id);
                ps.setString(2, report_sequence);               
                ps.setString(3, request.getParameter("can"));// /request.getParameter("pw")
                ps.setString(4, request.getParameter("year"));
                ps.setString(5, month);
                rs = ps.executeQuery();
                key_seq = (rs.next()) ? rs.getInt(1) : 0;
                documentExists = (key_seq != 0);
            } catch (Exception e) {
                SITLog.error(e, "trying to get key_seq from sit_documents in _monthly.jsp");
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }// check if report exists
        }
        if (key_seq == 0){// this means there isn't a record yet
            try{ // get sit_documents key_seq max+1
                ps = connection.prepareStatement("select document_seq.nextval from dual");
                rs = ps.executeQuery();
                if(rs.next()){
                    key_seq = rs.getInt(1);
                  
                } else {
                  end.append("problem getting key_seq<br>");
                }
            } catch (Exception e) {
                end.append("Exception: " + e.toString());
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }// try get sit_documents key_seq max+1
        }
        // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
        try{ // write to sit_document_images
            String file_name       = "M-" + key_seq + "-" + file_time + ".pdf"; //a-key_seq-timestamp
            File imgfile           = new File(tempDirectory + "SIT_" + file_time + ".pdf");
            FileInputStream fin    = new FileInputStream(imgfile);
            String blobString      = start.toString() + end.toString();
            imageSaved             = isImageSaved( connection, ps, rs, client_id, key_seq);
            //oracle.sql.BLOB myBlob = oracle.sql.BLOB.createTemporary(connection, false,oracle.sql.BLOB.DURATION_SESSION);
            //byte[] buff            = blobString.getBytes();
            //myBlob.putBytes(1,buff);
            //file_name="jasonTemp.pdf";
            // PRC 195487 Updated the logic. We only update the document image record in  sit_document_images table if the document exists and the document image record is saved. 
            // If not, we have to add a new one into sit_document_images table
            if(documentExists && imageSaved){
                ps = connection.prepareStatement(
                                    "update sit_document_images"
                                   +"   set file_blob=?,"
                                   +"       file_name=?,"
                                   +"       opercode=decode(opercode,'LOAD','LOAD',UPPER(?)),"
                                   +"       chngdate=sysdate"
                                   +" where client_id=?"
                                   +"       and key_seq=?");
                                   
                ps.setBinaryStream  (1, fin, (int) imgfile.length());
                ps.setString        (2, file_name);
                ps.setString        (3, sitUser.getUserName());
                ps.setString        (4, client_id); //client_id
                ps.setInt           (5, key_seq); //key_seq
            } else {
                ps = connection.prepareStatement(
                                    "insert into sit_document_images ("
                                   +"   client_id,"
                                   +"   key_seq,"
                                   +"   file_blob,"
                                   +"   file_name,"
                                   +"   access_count,"
                                   +"   opercode)"
                                   +" VALUES (?,?,?,?,?,UPPER(?))" );
                                   
                ps.setString(1, client_id); //client_id
                ps.setInt(2, key_seq); //key_seq
                //ps.setBlob(3, myBlob);
                ps.setBinaryStream(3, fin, (int) imgfile.length());
                ps.setString(4, file_name);
                ps.setInt(5, 0);
                ps.setString(6, sitUser.getUserName());
            }
            if( ps.executeUpdate() > 0){
              // record updated
            } else {
              SITLog.error("\r\nproblem inserting into sit_document_images for " + thisPage + " in _monthly.jsp\r\nps.executeUpdate !> 0");
              SITLog.info("Client_id (" + client_id + "), key_seq: (" + key_seq + ")");
            }
        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem inserting into sit_document_images for " + thisPage + " in _monthly.jsp\r\n");
            SITLog.info("client_id: " + client_id + ", key_seq: " + key_seq);
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try write to sit_document_images

 
 
       // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
       try{ // write to sit_documents
            if(documentExists){
                ps = connection.prepareStatement(
                                      "update sit_documents"
                                    + " set comments='FINALIZED: ' || sysdate,"
                                    + "     opercode = decode(opercode,'LOAD','LOAD',UPPER(?)), "    
                                    + "     chngdate = sysdate "
                                    + " where client_id=?"
                                    + "         and key_id=?"
                                    + "         and event_seq=?"
                                    + "         and  key_year=?"
                                    + "         and reference_no=?"
                                    + "         and key_seq=?");
                                
                ps.setString(1, sitUser.getUserName());
                ps.setString(2, client_id); //client_id
                ps.setString(3, request.getParameter("can")); //key_id
                ps.setString(4, report_sequence); //event_seq
                ps.setString(5, request.getParameter("year")); //key_year
                ps.setString(6, month); // reference_no
                ps.setInt(7, key_seq); //key_seq
                
            } else {
                ps = connection.prepareStatement(
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
                                  + "(?,'FINALIZED: ' || sysdate,?,?,?,?,?,?,?,?,UPPER(?))");
                                  
                ps.setString(1, client_id); //client_id
                ps.setString(2, description); //description
                ps.setString(3, "MONRPT"); //document_type
                ps.setString(4, report_sequence); //event_seq
                ps.setString(5, request.getParameter("can")); //key_id
                ps.setInt(6, key_seq); //key_seq
                ps.setString(7, "A"); //key_type
                ps.setString(8, request.getParameter("year")); //key_year
                ps.setString(9, month);
                ps.setString(10, sitUser.getUserName() );
            }       


           //ps.executeUpdate();
           if( ps.executeUpdate() > 0){
              //SITLog.info("sit_documents table updated\r\n");
           } else {
              SITLog.info("problem inserting into sit_documents table. ps.execute !> 0\r\n");
           }

        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem inserting into sit_documents for " + thisPage + " in _monthly.jsp\r\n");
            SITLog.info("*****Insert code*****\r\nclient_id: " + client_id + ", description: " + description 
                      + ", report_sequence: " + report_sequence + ", request.getParameter(\"can\"): "+ request.getParameter("can") 
                      + ", key_seq: " + key_seq + ", request.getParameter(\"year\"): " + request.getParameter("year") 
                      + ", month: " + month + "\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try write to sit_documents
 
// PRC 194431 - 05/16/2018 - Harris County wants "Go to Cart" button to be displayed after the form is finalized
if ( finalize_on_pay 
    || "2000".equals( client_id )){ //add to cart 
  //SITLog.info("_monthly: inside finalize_on_pay block");
  //get Fakhar's totals

    CallableStatement cs         = null;
    try{
            //((oracle.jdbc.OracleConnection)connection).setSessionTimeZone(TimeZone.getDefault().getID());
            cs = connection.prepareCall("{ ?=call vit_utilities.get_amount_due_by_month(?,?,?,?) }");
            //cs = conn.prepareCall("{ ?=call vit_utilities.get_amount_due_by_month(client_id=>?,can=>?,year=>?) }");
            cs.registerOutParameter(1,oracle.jdbc.OracleTypes.CURSOR);
            cs.setString(2, client_id);
            cs.setString(3, request.getParameter("can"));
            cs.setString(4, request.getParameter("year"));
            cs.setString(5, month);
            cs.execute();
            rs = (ResultSet) cs.getObject(1);
            if(rs.next()){
               // SITLog.info("Fakhar...using client_id: " + client_id + ", request.getParameter(\"can\"): " + request.getParameter("can") + ", request.getParameter(\"year\"): " + request.getParameter("year") + ", month: " + month);
                //SITLog.info("msale_levybal: " + rs.getString("msale_levybal")+ "\r\n"
                         // + "msale_penbal: " + rs.getString("msale_penbal")+ "\r\n"
                         // + "AMOUNT_DUE: " + rs.getString("AMOUNT_DUE")+ "\r\n");

                fakharMin = rs.getDouble("msale_levybal") + rs.getDouble("msale_penbal");
                fakharTotal = rs.getString("AMOUNT_DUE");
                //SITLog.info("fakharMin is " + fakharMin + " and fakharTotal is " + fakharTotal);
              } else { // no records found
                 //SITLog.info("no records found from Fakhar");
                 fakharTotal = "0.00";
              }
    } catch(Exception e){
        out.print("exception: " + e.toString());
    } finally {
        if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
        if ( cs   != null ) { try { cs.close();   } catch (Exception e) {} cs   = null; }
    }
    if(!"0.00".equals(fakharTotal)){
        try{
          String [] monthsText = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
          String description2   =  (monthsText[Integer.parseInt(month)] + " " + request.getParameter("year"));
          //add to cart
          payments.add(new Payment(
              request.getParameter("can"),
              report_sequence, 
              request.getParameter("year"), 
              month, 
              description2, 
              fakharTotal, 
              "0.0", 
              fakharTotal, 
              String.valueOf(fakharMin), 
              "0.00")
          );
        }catch(Exception e){SITLog.error(e, "problem adding to payments");}
    }
}
// PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
if(!finalize_on_pay || Double.parseDouble(fakharTotal) == 0.00) { // set report_status to C 
      //SITLog.info("_monthly: updating report_status to 'C'\r\nfakharTotal = " + fakharTotal);
      try{ // update report_status
          // if dallas, update to O, otherwise, update to C
            ps = connection.prepareStatement(
                            "update sit_sales_master"
                           +" set report_status = 'C'," 
                           +"       opercode = decode(opercode,'LOAD','LOAD',UPPER(?)),"
                           +"       chngdate= sysdate,"
                           +"       finalize_date=CURRENT_TIMESTAMP "
                           +" where client_id=?"
                           +"       and can=?"
                           +"       and month=?"
                           +"       and year=?"
                           +"       and report_seq=?");
            ps.setString(1, "WEB-"+sitUser.getUserName() );
            ps.setString(2, client_id);
            ps.setString(3, request.getParameter("can"));
            ps.setString(4, request.getParameter("month"));
            ps.setString(5, request.getParameter("year"));
            ps.setString(6, report_sequence);

            if( ps.executeUpdate() > 0){
            ts.append("sit_sales_master was updated with a 'C'\r\n");
              //end.append("record updated<br>");
            } else {
              SITLog.info("\r\nsit_sales_master record report_status not updated " + thisPage + " in _monthly.jsp\r\nps.executeUpdate !> 0");
            }
            
      } catch (Exception e) {
            SITLog.error(e, "\r\nProblem setting report_status for " + thisPage + " in _monthly.jsp\r\n");
            SITLog.info("client_id ("+client_id+"), request.getParameter(\"can\") ("+request.getParameter("can")+"), request.getParameter(\"month\") ("+request.getParameter("month")+"), request.getParameter(\"year\") ("+request.getParameter("year")+"), report_sequence ("+report_sequence+")\r\n");
            ts.append("The exception: " + e.toString()+"\r\n");
      } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
      }// try update report_status

}
        
        String emailFrom = nvl(configuration.getProperty("JUR_EMAIL_ADDRESS"),sitAccount.JUR_EMAIL_ADDRESS);
        
        int noteseq = 0;
        try{ // get noteseq nextval
            ps = connection.prepareStatement("select notes_seq.nextval from dual");
            rs = ps.executeQuery();
            noteseq = rs.next() ? rs.getInt(1) : 0;
           // SITLog.info("noteseq is " + noteseq + "\r\n");
        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem running sequence for notes on " + thisPage + " in _monthly.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try update report_status
        String preNote = "Monthly Sales Report for "+request.getParameter("month")+"/"+request.getParameter("year")+" finalized on ";// || to_char(sysdate, 'MM/DD/YYYY')
        //String user_name = "WEB-" + session.getAttribute("username").toString();
        //user_name = user_name.substring(0, Math.min(user_name.length(), 30));
        
        //PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
        try{ // get noteseq nextval
            ps = connection.prepareStatement(
                                "INSERT INTO notes ("
                               +"   client_id,"
                               +"   can,"
                               +"   noteseq,"
                               +"   notexdte,"
                               +"   note,"
                               +"   msgcode,"
                               +"   opercode,"
                               +"   chngdate) "
                               +"VALUES (?,?,?,  sysdate, ? || TO_CHAR(sysdate, 'MM/DD/YYYY'), ?, UPPER(?), sysdate)");
            ps.setString(1, client_id); //client_id
            ps.setString(2, request.getParameter("can")); //can
            ps.setInt(3, noteseq); //noteseq
            ps.setString(4, preNote); //note Monthly Sales Report for March 2015 finalized on March 2015 
            ps.setString(5, "MSG"); //msgcode = MSG
            ps.setString(6, "WEB-"+sitUser.getUserName()); //opercode = user name

            if( ps.executeUpdate() > 0){
             // SITLog.info("inserted note\r\n");
            }else{
              SITLog.error("failed to insert note for " + request.getParameter("can") + "\r\n");
            }

        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem inserting notes on " + thisPage + " in _monthly.jsp\r\n");
            ts.append("The exception: " + e.toString()+"\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try update report_status
		
        if(isDefined(emailFrom)){
            // Send email
            try { 
              //String emailFrom = "test@lgbs.com";
              String emailSubject = months[Integer.parseInt(request.getParameter("month"))] + " " + request.getParameter("year") + " SALES REPORT";
              //String emailBody = "Your " + emailSubject + " has been finalized for acct: " + request.getParameter("can") + ".";
			  contactInfo.append("<pre>");
			  contactInfo.append("Your " + emailSubject + " has been finalized for acct: " + request.getParameter("can")+ "<br/><br/>");
			  contactInfo.append("<Strong><i>"+nvl(configuration.getProperty("JUR_ADDRESS1"),sitAccount.JUR_ADDRESS1)+" "+"TAX OFFICE<br/>");
			  contactInfo.append(nvl(configuration.getProperty("JUR_ADDRESS2"),sitAccount.JUR_ADDRESS2)+"<br/>");
			  contactInfo.append(nvl(configuration.getProperty("JUR_ADDRESS4"),sitAccount.JUR_ADDRESS4)+"<br/>");
			  contactInfo.append(nvl(configuration.getProperty("JUR_PHONE1"),sitAccount.JUR_PHONE1)+"<br/>");
			  contactInfo.append(emailFrom+"</i></Strong>");
			  contactInfo.append("</pre>");
              //                           from,                          to,                                subject,       body
             act.util.EMail.sendHtml( emailFrom,nvl(session.getAttribute("email"),"duc.nguyen@lgbs.com"), emailSubject, contactInfo.toString() );
            } catch (Exception e) { SITLog.error(e, "\r\nProblem sending email to can ("+request.getParameter("can")+") for " + thisPage + " in _monthly.jsp\r\n"); }
        }

      } // if (! "C".equals(report_status) )


  } catch (Exception e) {
    SITLog.error(e, "\r\nProblem in outer try for " + thisPage + " in _monthly.jsp\r\n");
    ts.append("The exception: " + e.toString()+"\r\n");
  } finally {
      try { rs.close(); } catch (Exception e) { }
      rs = null;
      try { ps.close(); } catch (Exception e) { }
      ps = null;
      if (connection != null) {
          try { connection.close(); } catch (Exception e) { }
          connection = null;
      }
  }// outer try  
   try {

              //SITLog.info(ts.toString());
              FileOutputStream fos = new FileOutputStream("/usr2/webtemp/SIT_troubleshooting.txt");
               byte[] bytesArray = ts.toString().getBytes();
                  fos.write(bytesArray); 
             fos.flush();
             if (fos != null) { fos.close(); }
              Runtime.getRuntime().exec( "/usr/bin/chmod 666 /usr2/webtemp/SIT_troubleshooting.txt" );
            }catch(Exception e){SITLog.error(e, "writing troubleshooting file\r\n");}
  %><%!
  
	// PRC 195487 this function will check if the document image  record is saved into sit_document_images
    public boolean isImageSaved ( Connection conn,
                                   PreparedStatement ps,
                                   ResultSet rs,
                                   String clientId,
                                   int key) throws Exception {
        boolean isSaved = false;
        try {
            ps = conn.prepareStatement(
                            "select count(*) as total"
                          + "   from sit_document_images"
                          + " where client_id = ?"
                          + "       and key_seq = ?"
                                      );
            ps.setString(1,clientId);
            ps.setInt(2,key);
            
            rs = ps.executeQuery();
            
            if(! rs.isBeforeFirst() ) { isSaved = false;}
            
            if ( rs.next() ) {
                int count = Integer.parseInt(rs.getString("total"));
                if (count > 0 ) { isSaved = true;}
            }

        } catch (Exception e) {
            throw e;
        } finally {
            try { ps.close();} catch(Exception e){}
			ps = null;
			try { rs.close();} catch(Exception e){}
			rs = null;
        }
        
        return isSaved;
            
    }
    
  %>