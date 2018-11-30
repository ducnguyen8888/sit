<%--
      DN - 08/07/2018 - PRC 198408
        Removed a condition:  opercode = "SIT_INQ"
--%><%
//String            report_status = "";
//String            report_sequence    = (isDefined(request.getParameter("report_seq")))?request.getParameter("report_seq"):"0"; // sit_sales_master
int               key_seq       = 0; // sit_documents
String            document_type = "";
//Connection        connection    = null;
//PreparedStatement ps            = null;
//ResultSet         rs            = null;

//StringBuffer      sb            = new StringBuffer();
//StringBuffer      bigDoc        = new StringBuffer();
//String            client_id     = null;
//out.print("report_sequence is " + report_sequence + "<br>");
java.text.DateFormat dateFormat = new java.text.SimpleDateFormat("MMddyyyyHHmmss");
java.util.Calendar cal = java.util.Calendar.getInstance();
String file_time = dateFormat.format(cal.getTime()); //a-key_seq-timestamp


//client_id     = request.getParameter("client_id");
//month         = nvl(request.getParameter("month"), "");
//year          = nvl(request.getParameter("year"), "");
//can           = nvl(request.getParameter("can"), "");

document_type = (Integer.parseInt(month) == 13) ? "ANNDEC" : "MONRPT" ;
if (isDefined(client_id)){
  
  connection = connect();
  month = month.length() == 1 ? "0" + month : month; // makes 7 = 07

  try{  // big outer try

      //try{ // get report_seq and status
      //    ps = connection.prepareStatement("select report_status from sit_sales_master "
      //                                   + "where client_id=? and can=? and month=? and year=? and report_seq=?");
      //    ps.setString(1, client_id);
      //    ps.setString(2, can);// /request.getParameter("pw")
      //    ps.setString(3, month);
      //    ps.setString(4, year);
      //    ps.setString(5, report_sequence);
      //    rs = ps.executeQuery();
      //    if(rs.next()){
      //      report_status = rs.getString(1);
      //      //bigDoc.append("seq: " + rs.getString(1) + ", status: " + rs.getString(2) + "<br>");
      //    } else {
      //      SITLog.warn("\r\nno records found while searching for report_sequence "+report_sequence+"and report_status in viewForm.jsp\r\n");
      //    }
      //} catch (Exception e) {
      //    SITLog.error(e, "\r\ngetting report_status from sales_master in viewForm.jsp\r\n");
      //    SITLog.info("\r\nclient_id: " + client_id + ", can: " + can + ", month: " + month + ", year: " + year + ", report_sequence: " + report_sequence + "\r\n");
      //    bigDoc.append("Exception: " + e.toString());
      //} finally {
      //    try { rs.close(); } catch (Exception e) { }
      //    rs = null;
      //    try { ps.close(); } catch (Exception e) { }
      //    ps = null;
      //}// try get report_seq and status
      
      //PRC 198408 - 08/07/2018 - Removed the opercode = "SIT_INQ"
      try{ // get key_seq
          ps = connection.prepareStatement(
                                "select max (key_seq)"
                              + " from sit_documents"
                              + " where client_id=?"
                              + "       and key_id=?"
                              + "       and key_year=?"
                              + "       and reference_no=?"
                              + "       and document_type=?"
                              + "       and event_seq=?");//event_seq=?
                              
          ps.setString(1, client_id);
          ps.setString(2, can);
          ps.setString(3, year);
          ps.setInt(4, Integer.parseInt(month));//ps.setInt(4, report_seq);
          ps.setString(5, document_type);
          ps.setString(6, report_sequence);
          rs = ps.executeQuery();
          if(rs.next()){
            key_seq = rs.getInt(1);
          }
      } catch (Exception e) {
          SITLog.error(e, "\r\ngetting key_seq from sit_documents in viewForm.jsp\r\n");
      } finally {
          try { rs.close(); } catch (Exception e) { }
          rs = null;
          try { ps.close(); } catch (Exception e) { }
          ps = null;
      }// try get key_seq      
    
      try{ // get blob
          ps = connection.prepareStatement(
                                "select file_blob"
                               +" from sit_document_images"
                               +" where client_id=?"
                               +"       and key_seq = ?");
          ps.setString(1, client_id);
          ps.setInt(2, key_seq);
          rs = ps.executeQuery();

          if(rs.next()){
            Blob blob = rs.getBlob(1);
            try {

              InputStream is = blob.getBinaryStream();
              FileOutputStream fos = new FileOutputStream( tempDirectory +"SIT_VIEW_"+file_time+".pdf");
               
              int b = 0;
              while ((b = is.read()) != -1)
              {
                  fos.write(b); 
              }
             Runtime.getRuntime().exec( "/usr/bin/chmod 666 /usr2/webtemp/SIT_VIEW_"+file_time+".pdf" );
            } catch (Exception e) {
                SITLog.error(e, "\r\ngetting file_blob bytes in viewForm.jsp\r\n");
            } finally {
                // try { os.close(); } catch (Exception e) {} os = null;
            }
          } else {
            //SITLog.warn("\r\nno file_blob in viewForm.jsp\r\n");
          }
      } catch (Exception e) {
          SITLog.error(e, "\r\ngetting file_blob in _viewForm.inc\r\n");
      } finally {
          try { rs.close(); } catch (Exception e) { }
          rs = null;
          try { ps.close(); } catch (Exception e) { }
          ps = null;
      }// try get blob      

  } catch (Exception e) {
    SITLog.error(e, "\r\nbig outer try in viewForm.jsp\r\n");
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

}//if (isDefined(client_id)){

// *********************** Container for blob *********************** //


        //out.print("report_seq is " + report_seq + "<br>");
        //out.print("report_status is " + report_status + "<br>");
        //out.print("client_id is " + client_id + "<br>");
        //out.print("can is " + can + "<br>");
        //out.print("year is " + year + "<br>");
        //out.print("document_type is " + document_type + "<br>");
      if(key_seq > 0){
        pdf_url = tempURL + "SIT_VIEW_"+file_time+".pdf";
      }else {
        pdf_url = "#";
        //SITLog.error("Didn't get PDF");
      }


// *********************** /Container for blob *********************** //


// return http://chaos:7778/dev60temp/filename
%>