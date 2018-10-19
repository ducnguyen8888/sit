<%--
    DN - 04/19/2018 - PRC 195488
        - Updated the query to save the breakdown sales and breakdown sales amounts in sit_sales_master table
        - This is only applied for clients starting in the middle of the year and they have to manually input data for the breakdown sales and breakdown sales amount
     DN - 08/07/2018 - PRC 198588
        - Moved getClientPref and getSitClientPref function to "_configuation.inc" file
        - Used declarationYear when inserting into table "notes"
     DN - 08/07/2018 - PRC 198408
        -Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
--%>
<%


  java.text.DateFormat dateFormat   = new java.text.SimpleDateFormat("MMddyyyyHHmmss");
  java.util.Calendar cal            = java.util.Calendar.getInstance();
  String file_time                  = dateFormat.format(cal.getTime()); //a-key_seq-timestamp
  StringBuffer contactInfo          = new StringBuffer();
  
  SITUser    sitUser                = sitAccount.getUser();

  

  try{
        /* **************** Write initial temp html file ********************* */


        BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(tempDirectory + "SIT_" + file_time + ".html"), "UTF-8"));
        try {
            bw.write(start.toString() +  end.toString() + "</body></html>");
        } finally {
            bw.close();
        }
        Runtime.getRuntime().exec( "/usr/bin/chmod 666 " + tempDirectory + "SIT_" + file_time + ".html" );

        /* **************** Send file info to PHP page ********************* */
        String USER_AGENT = "Mozilla/5.0";
        //String url2 = "http://apollo/mpdf/examples/jasonTest.php";
        java.net.URL obj = new java.net.URL(pdfConverterURL);
        java.net.HttpURLConnection con = (java.net.HttpURLConnection) obj.openConnection();

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
  } catch(Exception e){SITLog.error(e, "\r\nProblem doing html/pdf conversion for " + thisPage + " in _monthly.jsp\r\n"); }


  String description = request.getParameter("year") + " ANNUAL REPORT - WEB";
  String report_status = "";
 report_seq = 1; // sit_sales_master
  int key_seq = 0; // sit_documents
  boolean notStarted = true;
  
  String form_annual = "";
  int dealer_type = 0;
  if ("50-246".equals(form_name)) {form_annual = "50_244"; dealer_type = 1; } else // 1 motor vehicle
  if ("50-260".equals(form_name)) {form_annual = "50_259"; dealer_type = 2; } else // 2 outboard
  if ("50-266".equals(form_name)) {form_annual = "50_265"; dealer_type = 3; } else // 3 heavy equipment
  if ("50-268".equals(form_name)) {form_annual = "50_267"; dealer_type = 4; }      // 4 housing

  Connection connection = null;
  PreparedStatement ps = null;
  ResultSet rs = null;

  connection = connect();

  try{  // big outer try


      try { // check to see if this has been started
                  
          ps = connection.prepareStatement(
                                "select count(*)"
                              + "   from sit_sales_master "
                              + " where client_id=?"
                              + "       and can=?"
                              + "       and year=?"
                              + "       and month=13");                                           
          ps.setString(1, client_id);
          ps.setString(2, request.getParameter("can"));
          ps.setString(3, request.getParameter("year"));
          rs = ps.executeQuery();
          rs.next();
          notStarted = (rs.getInt(1) == 0);
         // end.append("notStarted is " + notStarted + "<br>");
      } catch (Exception e) { 
          SITLog.error(e, "\r\nProblem getting record count for " + thisPage + " in _yearly.jsp\r\n");
      } finally {
          try { rs.close(); } catch (Exception e) { }
          rs = null;
          try { ps.close(); } catch (Exception e) { }
          ps = null;
      } // check to see if this has been started
      
      if(notStarted){
        // get max(report_seq) + 1 and start one

          //try{ // max(get report_seq + 1)
          //    ps = connection.prepareStatement("SELECT nvl(max(report_seq)+1, 1) FROM sit_sales_master WHERE client_id=? AND can=?");
          //    ps.setString(1, client_id);
          //    ps.setString(2, can);// /request.getParameter("pw")
          //    rs = ps.executeQuery();
          //    report_seq = (rs.next()) ? rs.getInt(1) : 1;
          //} catch (Exception e) {
          //    end.append("Exception: " + e.toString());
          //} finally {
          //    try { rs.close(); } catch (Exception e) { }
          //    rs = null;
          //    try { ps.close(); } catch (Exception e) { }
          //    ps = null;
          //}// try get report_seq and status
          
          //PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
          try { // create new record
                  ps = connection.prepareStatement(
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
                                  + "VALUES (?, ?, ?, ?, ?, 'O', ?, ?, 'N', ?, sysdate) ");
                                  
                  ps.setString  (1, client_id);
                  ps.setString  (2, request.getParameter("can"));
                  ps.setString  (3, request.getParameter("year"));
                  ps.setInt     (4, 13); // month will be 0 
                  ps.setInt     (5, report_seq);
                  ps.setInt     (6, dealer_type);
                  ps.setString  (7, form_annual);
                  ps.setString  (8, sitUser.getUserName());
                  ps.executeUpdate();
                  //end.append("inserted new sales master record");
          } catch (Exception e) { 
            SITLog.error(e, "\r\nProblem inserting into sit_sales_master for " + thisPage + " in _yearly.jsp\r\n");
          } finally {
              try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
              rs = null;
              try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
              ps = null;
          }// try create new record 


      } else { // if it's already been started

          try{ // get report_seq and status
              ps = connection.prepareStatement(
                                "select report_seq,"
                              + "       report_status"
                              + " from sit_sales_master"
                              + " where client_id=?"
                              + "       and can=?"
                              + "       and year=?"
                              + "       and month=13 ");
                              
              ps.setString (1, client_id);
              ps.setString (2, request.getParameter("can"));// /request.getParameter("pw")
              ps.setString (3, request.getParameter("year"));
              rs = ps.executeQuery();
              if(rs.next()){
                report_seq = rs.getInt(1);
                report_status = rs.getString(2);
                end.append("seq: " + rs.getString(1) + ", status: " + rs.getString(2));
              } else {
                end.append("no records found while searching for report_seq and report_status<br>");
              }
          } catch (Exception e) {
              SITLog.error(e, "\r\nProblem selecting report_seq and report_status for " + thisPage + " in _yearly.jsp\r\n");
          } finally {
              try { rs.close(); } catch (Exception e) { }
              rs = null;
              try { ps.close(); } catch (Exception e) { }
              ps = null;
          }// try get report_seq and status



      }

      
      if (! "C".equals(report_status) ){

        try{ // get sit_documents key_seq max+1
            //ps = connection.prepareStatement("select max(key_seq)+1 from sit_document_images");
            ps = connection.prepareStatement("select document_seq.nextval from dual");
            rs = ps.executeQuery();
            if(rs.next()){
              key_seq = rs.getInt(1);
            } else {
              end.append("problem getting key_seq<br>");
            }
        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem getting document_seq.nextval for " + thisPage + " in _yearly.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try get sit_documents key_seq max+1
 

       // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
       try{ // write to sit_document_images
            ps = connection.prepareStatement(
                                "insert into sit_document_images"
                              + "   (client_id,"
                              + "   key_seq,"
                              + "   file_blob,"
                              + "   file_name,"
                              + "   access_count,"
                              + "   opercode)"
                              + " VALUES (?,?,?,?,?,UPPER(?) )" );
                              
            //java.text.DateFormat dateFormat = new java.text.SimpleDateFormat("MMddyyyyHHmmss");
            //java.util.Calendar cal = java.util.Calendar.getInstance();
            String file_name = "A-" + key_seq + "-" + file_time + ".pdf"; //a-key_seq-timestamp

            File imgfile = new File(tempDirectory + "SIT_" + file_time+".pdf");
            FileInputStream fin = new FileInputStream(imgfile);

            String blobString = start.toString() + end.toString();
            oracle.sql.BLOB myBlob = oracle.sql.BLOB.createTemporary(connection, false,oracle.sql.BLOB.DURATION_SESSION);
            byte[] buff = blobString.getBytes();
            myBlob.putBytes(1,buff);

            ps.setString        (1, client_id); //client_id
            ps.setInt           (2, key_seq); //key_seq
            ps.setBinaryStream  (3, fin, (int) imgfile.length());
            ps.setString        (4, file_name);
            ps.setInt           (5, 0);
            ps.setString        (6, sitUser.getUserName() );
            if( ps.executeUpdate() > 0){
              //end.append("record updated<br>");
            } else {
              SITLog.info("\r\nProblem inserting blob for " + thisPage + " in _yearly.jsp\r\n");
            }
            
        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem inserting blob for " + thisPage + " in _yearly.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try write to sit_document_images
        
       // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
       try{ // write to sit_documents
            ps = connection.prepareStatement(""
                      + "insert into sit_documents "
                      + "   (client_id,"
                      + "   comments,"
                      + "   description,"
                      + "   document_type,"
                      + "   event_seq,"
                      + "   key_id,"
                      + "   key_seq,"
                      + "   key_type,"
                      + "   key_year,"
                      + "   reference_no,"
                      + "   opercode)"
                      + " VALUES "
                      + "   (?,'FINALIZED: ' || sysdate,?,?,?,?,?,?,?,?,UPPER(?) )" );
                      
            ps.setString    (1, client_id); //client_id
            ps.setString    (2, description); //description
            ps.setString    (3, "ANNDEC"); //document_type
            ps.setInt       (4, report_seq); //event_seq
            ps.setString    (5, request.getParameter("can")); //key_id
            ps.setInt       (6, key_seq); //key_seq
            ps.setString    (7, "A"); //key_type
            ps.setString    (8, request.getParameter("year")); //key_year
            ps.setInt       (9, 13);
            ps.setString    (10, sitUser.getUserName() );
            ps.executeUpdate();
           // if( ps.executeUpdate() > 0){
              //end.append("record updated<br>");
           // } else {
              //end.append("problem inserting into sit_documents<br>");
           // }

        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem inserting into sit_documents for " + thisPage + " in _yearly.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try write to sit_documents
        
       //PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
       try{ // update report_status
            // PRC 195488 - Updated query to save the breakdown sales and breakdown sales amounts in sit_sales_master table
            if ( importedMonths ) {
                ps = connection.prepareStatement("update sit_sales_master"
                                                +" set report_status = 'C',"
                                                +"      inventory_sales_units = ?,"
                                                +"      fleet_sales_units = ?,"
                                                +"      dealer_sales_units = ?,"
                                                +"      subsequent_sales_units = ?,"
                                                +"      retail_sales_units = ?,"
                                                +"      inventory_sales_amount = ?,"
                                                +"      fleet_sales_amount = ?,"
                                                +"      dealer_sales_amount = ?,"
                                                +"      subsequent_sales_amount = ?,"
                                                +"      retail_sales_amount = ?,"
                                                +"      finalize_date=CURRENT_TIMESTAMP, "
                                                +"      chngdate = sysdate,"
                                                +"      opercode = decode(opercode,'LOAD', 'LOAD',UPPER(?) )"
                                                +"  where client_id=? and can=? and month=? and year=? ");
                ps.setString(1, invCount);
                ps.setString(2, fsCount);
                ps.setString(3, dsCount);
                ps.setString(4, ssCount);
                ps.setString(5, rsCount);
                
                ps.setString(6, invAmount);
                ps.setString(7, fsAmount);
                ps.setString(8, dsAmount);
                ps.setString(9, ssAmount);
                ps.setString(10, rsAmount);
                
                ps.setString(11, sitUser.getUserName() );
                
                ps.setString(12, client_id);
                ps.setString(13, request.getParameter("can"));
                ps.setInt   (14, 13);
                ps.setString(15, request.getParameter("year"));
                
                
            } else {
                ps = connection.prepareStatement(
                                    "update sit_sales_master"
                                  + " set report_status = 'C',"
                                  + "     finalize_date=CURRENT_TIMESTAMP, "
                                  + "     chngdate = sysdate,"
                                  + "     opercode = decode(opercode,'LOAD', 'LOAD',UPPER(?) "
                                  + " where client_id=?"
                                  + "       and can=?"
                                  + "       and month=?"
                                  + "       and year=?");
                                  
                ps.setString    (1, sitUser.getUserName() );
                ps.setString    (2, client_id);
                ps.setString    (3, request.getParameter("can"));
                ps.setInt       (4, 13);
                ps.setString    (5, request.getParameter("year"));
            }
            
            //ps.setInt(5, report_seq);

            //end.append("report_seq: " + report_seq + "<br>");
            //end.append("key_seq: " + key_seq + "<br>");
            //end.append("client_id: " + client_id + "<br>");
            //end.append("can: " + request.getParameter("can") + "<br>");
            //end.append("month: " + request.getParameter("month") + "<br>");
            //end.append("year: " + request.getParameter("year") + "<br>");
            //end.append("form_name: " + form_name + "<br>");
            
            if( ps.executeUpdate() > 0){
              //end.append("record updated<br>");
            } else {
              //end.append("problem inserting into sit_documents");
            }
            
        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem setting report_status for " + thisPage + " in _yearly.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try update report_status

        int noteseq = 0;
        try{ // get noteseq nextval
            ps = connection.prepareStatement("select notes_seq.nextval from dual");
            rs = ps.executeQuery();
            noteseq = rs.next() ? rs.getInt(1) : 0;
            SITLog.info("noteseq is " + noteseq + "\r\n");
        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem running sequence for notes on " + thisPage + " in _yearly.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try update report_status
          String preNote= "Yearly Sales Report for %d (%s Sales) finalized on ";
        String user_name = "WEB-" + session.getAttribute("username").toString();
        user_name = user_name.substring(0, Math.min(user_name.length(), 30));
         
        // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
        try{ // get noteseq nextval
            ps = connection.prepareStatement(
                                "INSERT INTO notes("
                              + "   client_id,"
                              + "   can,"
                              + "   noteseq,"
                              + "   notexdte,"
                              + "   note,"
                              + "   msgcode,"
                              + "   opercode,"
                              + "   chngdate) "
                              + " VALUES (?,?,?,  sysdate, ? || sysdate, ?, UPPER(?), sysdate)");
                              
            ps.setString(1, client_id); //client_id
            ps.setString(2, request.getParameter("can")); //can
            ps.setInt(3, noteseq); //noteseq
            ps.setString(4, String.format(preNote, declarationYear, year)); //note Monthly Sales Report for March 2015 finalized on March 2015
            ps.setString(5, "MSG"); //msgcode = MSG
            ps.setString(6,"WEB-"+sitUser.getUserName() ); //opercode = Login user name

            if( ps.executeUpdate() > 0){
             // SITLog.info("inserted note\r\n");
            }else{
              SITLog.error("failed to insert note for " + request.getParameter("can") + "\r\n");
            }

        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem inserting notes on " + thisPage + " in _yearly.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try update report_status

      
		String emailFrom = nvl(getSitClientPref(connection, ps, rs,client_id,"JUR_EMAIL_ADDRESS"),""); 

        if(isDefined(emailFrom)){

          // Send email
          try { 
            //String emailFrom = "jason.cook@lgbs.com";
            String emailSubject = request.getParameter("year") + " ANNUAL REPORT";
            //String emailBody = "Your " + emailSubject + " has been finalized for acct: " + request.getParameter("can") + ".";
			  contactInfo.append("<pre>");
			  contactInfo.append("Your " + emailSubject + " has been finalized for acct: " + request.getParameter("can")+ "<br/><br/>");
			  contactInfo.append("<Strong><i>"+nvl(getClientPref(connection, ps, rs, client_id,"JUR_ADDRESS1"),"")+" "+"TAX OFFICE<br/>");
			  contactInfo.append(nvl(getClientPref(connection, ps, rs, client_id,"JUR_ADDRESS2"),"")+"<br/>");
			  contactInfo.append(nvl(getClientPref(connection, ps, rs, client_id,"JUR_ADDRESS4"),"")+"<br/>");
			  contactInfo.append(nvl(getClientPref(connection, ps, rs, client_id,"JUR_PHONE1"),"")+"<br/>");
			  contactInfo.append(emailFrom+"</i></Strong>");
			  contactInfo.append("</pre>");
              //                           from,                          to,                                subject,       body
           act.util.EMail.sendHtml( emailFrom, nvl(session.getAttribute("email"),"duc.nguyen@lgbs.com"), emailSubject, contactInfo.toString() );
          } catch (Exception e) { SITLog.error(e, "\r\nProblem sending email email for " + thisPage + " in _yearly.jsp\r\n");}


		}

      } // if (! "C".equals(report_status) )

  } catch (Exception e) {
    end.append("Exception big outer: " + e.toString());
    out.print("Exception: " + e.toString());
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
%>