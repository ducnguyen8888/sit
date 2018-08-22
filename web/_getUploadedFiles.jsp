<%@ include file="_configuration.inc"%><%

/* TESTING
    String client_id = "79000000";
    can = "H000001";
    month="09";
    year="2016";
    report_seq = 1;
*/
    String client_id = request.getParameter("client_id");
    can              = request.getParameter("can");
    month            = request.getParameter("month");
    year             = request.getParameter("year");
    report_seq       = Integer.parseInt(request.getParameter("report_seq"));
          boolean uploaded = false;
          boolean docIsFinalized = false;
          Connection        add_conn     = null;
          PreparedStatement add_ps       = null;
          ResultSet         add_rs       = null;
          String            wkey_seq = null;
          long              amillis = System.currentTimeMillis() / 1000;
          String            aFileName = "SIT_ADDLVIEW_"+amillis+".pdf";
          StringBuffer testing = new StringBuffer();
          month = month.length() == 1 ? "0" + month : month; // makes 7 = 07

          try{

              try {
                  add_conn = connect();
              } catch (Exception e) {
                  SITLog.error(e, "Connecting to database for addl file link");
              } 
          
              //verify not finalized
              //try{ 
              //    add_ps = add_conn.prepareStatement("select count(*) from sit_sales_master where client_id = ? and can=? and month=? and year=? and report_status != 'C'");
              //    //testing.append("client_id ("+client_id+"), can ("+can+"), year ("+year+"), month ("+month+")");
              //    add_ps.setString(1, client_id);
              //    add_ps.setString(2, can);
              //    add_ps.setString(3, month);
              //    add_ps.setString(4, year);
              //    add_rs = add_ps.executeQuery();
              //    add_rs.next();
              //    docIsFinalized = (add_rs.getInt(1) == 0);
              //    
              //} catch (Exception e) {
              //    SITLog.error(e, "\r\nchecking for finalized document in _getUploadedFiles.inc\r\n");
              //} finally {
              //    try { add_rs.close(); } catch (Exception e) { } add_rs = null;
              //    try { add_ps.close(); } catch (Exception e) { } add_ps = null;
              //}// try get key_seq 
          



              //if(!docIsFinalized){
                  try{ 
                      add_ps = add_conn.prepareStatement("select key_seq "
                                                       + "from sit_documents " // can           year          month
                                                       + "where client_id=? and key_id=? and key_year=? and reference_no=? and event_seq=? and description like '%WEB DEALER%'");
                      //testing.append("client_id ("+client_id+"), can ("+can+"), year ("+year+"), month ("+month+")");
                      add_ps.setString(1, client_id);
                      add_ps.setString(2, can);
                      add_ps.setString(3, year);
                      add_ps.setString(4, month);
                      add_ps.setInt(5, report_seq);
                      add_rs = add_ps.executeQuery();
                      if(add_rs.next()){
                        wkey_seq = add_rs.getString(1);
                      }
                  } catch (Exception e) {
                      SITLog.error(e, "\r\ngetting wkey_seq from sit_documents in _getUploadedFiles.inc\r\n");
                  } finally {
                      try { add_rs.close(); } catch (Exception e) { } add_rs = null;
                      try { add_ps.close(); } catch (Exception e) { } add_ps = null;
                  }// try get key_seq 

                  if(isDefined(wkey_seq)){
                    try{ // get blob
                        add_ps = add_conn.prepareStatement("select file_blob from sit_document_images where client_id=? and key_seq = ?");
                        add_ps.setString(1, client_id);
                        add_ps.setString(2, wkey_seq);
                        add_rs = add_ps.executeQuery();

                        if(add_rs.next()){
                          Blob blob = add_rs.getBlob(1);
                          FileOutputStream fos = null;
                          try {
                              int b = 0;
                              InputStream is = blob.getBinaryStream();
                              fos = new FileOutputStream("/usr2/webtemp/" + aFileName);
                              while ((b = is.read()) != -1){ fos.write(b); }
                              Runtime.getRuntime().exec( "/usr/bin/chmod 666 /usr2/webtemp/" + aFileName );
                          } catch (Exception e) {
                              SITLog.error(e, "\r\ngetting file_blob bytes in _getUploadedFiles.inc\r\n");
                          } finally {
                              try { fos.flush(); fos.close(); } catch (Exception e) {} fos = null;
                          }
                        } else {
                          SITLog.warn("\r\nno file_blob in _getUploadedFiles.inc\r\n");
                        }
                    } catch (Exception e) {
                        SITLog.error(e, "\r\nbig outer in _getUploadedFiles.inc\r\n");
                    } finally {
                        try { add_rs.close(); } catch (Exception e) { }
                        add_rs = null;
                        try { add_ps.close(); } catch (Exception e) { }
                        add_ps = null;
                    }// try get blob 
                  }//if isDefined(wkey_seq)

              //} // end verify not finalized
                

          } catch (Exception e) {
              SITLog.error(e, "Big outer for file link in _getUploadedFiles");
          } finally {
              try { add_conn.close(); } catch (Exception e) {} add_conn = null;
          }   
          
          testing.append("<strong>File uploaded?</strong> ");
                if (isDefined(wkey_seq)) {
                      testing.append("Yes - <a href=\"" + tempURL + aFileName + "\" target=\"_blank\">View File</a>");
                      //testing.append("{\"status\": \"success\",\"link\": \"here.com\"}");

                    } else {
                      testing.append("No");
                      //testing.append("{\"status\": \"failure\",\"link\": \"here.com\"}");
                    }
                    out.print(testing.toString());
%>