<%--
        DN - 01/30/2018 - PRC 194603 
            - Changed "Finalized" to "Submitted" and "Filed" to "PYMT Posted"
        DN - 10/02/2018 - PRC 205088
            - Added CAD No
            - Display "CAD No" controlled by codeset "SHOW_CAD_NO_IN_SIT_PORTAL"
--%>
    <div id="bodyTop" style="width:6">
        <div class="widgetWrangler" style="width: 900px;">
            <%
            if(showWaccount)
            {
                %>
                <div class="widget1" <% if (finalize_on_pay && "sales.jsp".equals(current_page)) out.print("style='margin-left: 175px;'"); %>>
                    <div class="wtitle"  style="text-align: left; padding-left: 10px;">Account Information</div>
                    <div id="account" style="padding: 0px 5px;max-width:250px;text-overflow:ellipsis;overflow:hidden;white-space:nowrap;">
                        <%= getAddress(dealership, sitAccount) %>
                    </div>
                </div>
                <%
            }
            %>

            <%
            if(showWyearSelect)
            {
                %>
                <div class="widget1">
                    <div class="wtitle">Select the Filing Year</div>
                    <div id="filingYear" style="padding: 15px 5px; text-align: center;">
                       <form id="yearForm" method="post" action="#">
                           <select name="yearSelect" id = "yearSelect">
                            <%
                                int userSelectedYear = nvl(year,0);
                                for ( int loopYear=currentYear; loopYear > currentYear-4; loopYear-- )
                                {
                                    out.println(String.format("<option value=%d %s>%d</option>",
                                                                loopYear,
                                                                (loopYear == userSelectedYear ? "selected" : ""),
                                                                loopYear
                                                                )
                                                    );
                                }
                                //boolean selectIt = false; // helps select most recent year records were added
                                //int yearCounter = java.util.Calendar.getInstance().get(java.util.Calendar.YEAR); //TODO: need to get this from SIT
                                //
                                //for(int i = 0; i < 3; i++){
                                //    selectIt = ( nvl(request.getParameter("year"), "").equals(""+yearCounter) ); //|| x == d.years.length-1 
                                //    out.println("<option value=\"" + yearCounter + "\" " + ((selectIt)?"selected":"") + ">" + yearCounter + "</option>");
                                //    yearCounter--;
                                //
                                //}
                            %>                   
                           </select>
                       </form>
                       <p style="padding-top: 10px;">This form will automatically<br>submit when you choose a year</p>
                    </div>
                </div>
                <%
            }
            %>

        <% if(showWyearDisplay){ %>    
        <div class="widget1">
            <div class="wtitle">Filing Year</div>
            <div id="filingYear" style="padding: 15px 5px; text-align: center;">
              <input style="text-align:center; width: 100px;" type="text" name="yearSelect" id="yearSelect" value="<%= nvl(request.getParameter("year"), "") %>" readonly>
              <p style="padding-top: 10px;">This shows the year's filing info</p>
            </div>
        </div>
        <% } %>

        <% if(showWyearMonthDisplay){ %>
        <div class="widget1">
            <div class="wtitle">Selected Year/Month</div>
            <% if (max_report_seq > 1){  %>
              <div id="filingYearMonth" style="padding: 0px 5px; text-align: center;">
            <% } else { %>
              <div id="filingYearMonth" style="padding: 12px 5px; text-align: center;">
            <% } %>
               <p style="font-size: 110%; padding-top: 10px; font-weight: bold;">Year / Month</p>
              <input type="text" id="yearDisplay" name="yearDisplay" style="text-align: center; width: 60px;" disabled="true" value="<%= request.getParameter("year") %>" />
              <% String [] monthsShort = {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }; %>
              <input type="text" id="monthDisplay" name="monthDisplay" style="text-align: center; width: 60px;" disabled="true" value="<%= monthsShort[Integer.parseInt(request.getParameter("month"))] %>" />
              <% if (max_report_seq > 1){ 
                    String selectme = "";
                    out.print("<br><div style='padding-top: 15px;'>");
                    out.print("Choose report: <select name='report_seq' id='report_seq_dd'>");
                    for(int i = 1; i <= max_report_seq; i++){
                      selectme = (report_seq == i) ? "selected" : "";
                      out.print("<option value='"+i+"' "+selectme+" >Report "+i+"</option>");
                    }
                    out.print("/<select></div>");
               } %>
            </div>
        </div>
        <% } %>

        <% if (showLegend) { %>
          <div class="widget1" id="legendWidget">
            <div class="wtitle">Legend</div>
            <div style="padding: 12px 5px; text-align: center;">
                <table style="margin-left: 25px;">
                  <!-- PRC 194603 Changed Finalized to Submitted and Filed to PYMT Posted -->
                  <tr>
                    <td style="padding: 5px;"><i class="fa fa-times"></i></td>
                    <td style="padding: 5px; text-align: left;">Not submitted/payment posted</td>
                  </tr>
                  <tr>
                    <td style="padding: 5px;"><i class="fa fa-check-square-o"></i></td>
                    <td style="padding: 5px; text-align: left;">Some submitted/payment posted</td>
                  </tr>
                  <tr>
                    <td style="padding: 5px;"><i class="fa fa-check"></i></td>
                    <td style="padding: 5px; text-align: left;">All submitted/payment posted</td>
                  </tr>
                </table>
            </div>
        </div>
        <% } /* showLegend */ %>

        <% if (showUpload) { %>
        <%
          session.setAttribute("uCan", request.getParameter("can")); // used on fileUpload page
          session.setAttribute("uMonth", request.getParameter("month")); // used on fileUpload page
          session.setAttribute("uYear", request.getParameter("year")); // used on fileUpload page
          //boolean uploaded = false;
          //boolean docIsFinalized = false;
          Connection        add_conn     = null;
          PreparedStatement add_ps       = null;
          ResultSet         add_rs       = null;
          //String            wkey_seq = null;
          //long              amillis = System.currentTimeMillis() / 1000;
          //String            aFileName = "SIT_ADDLVIEW_"+amillis+".pdf";
          //StringBuffer testing = new StringBuffer();
          //month = month.length() == 1 ? "0" + month : month; // makes 7 = 07
//
          try{
            // try {
            //     add_conn = connect();
            // } catch (Exception e) {
            //     SITLog.error(e, "Connecting to database for addl file link");
            // } 
            // //verify not finalized
            // try{ 
            //     add_ps = add_conn.prepareStatement("select count(*) from sit_sales_master where client_id = ? and can=? and month=? and year=? and report_status != 'C'");
            //     //testing.append("client_id ("+client_id+"), can ("+can+"), year ("+year+"), month ("+month+")");
            //     add_ps.setString(1, client_id);
            //     add_ps.setString(2, can);
            //     add_ps.setString(3, month);
            //     add_ps.setString(4, year);
            //     add_rs = add_ps.executeQuery();
            //     add_rs.next();
            //     docIsFinalized = (add_rs.getInt(1) == 0);
            //     
            // } catch (Exception e) {
            //     SITLog.error(e, "\r\nchecking for finalized document in _widgets.inc\r\n");
            // } finally {
            //     try { add_rs.close(); } catch (Exception e) { } add_rs = null;
            //     try { add_ps.close(); } catch (Exception e) { } add_ps = null;
            // }// try get key_seq 
          //    if(!docIsFinalized){
          //        try{ 
          //            add_ps = add_conn.prepareStatement("select key_seq "
          //                                             + "from sit_documents " // can           year          month
          //                                             + "where client_id=? and key_id=? and key_year=? and reference_no=? and event_seq=? and description like '%WEB DEALER%'");
          //            //testing.append("client_id ("+client_id+"), can ("+can+"), year ("+year+"), month ("+month+")");
          //            add_ps.setString(1, client_id);
          //            add_ps.setString(2, can);
          //            add_ps.setString(3, year);
          //            add_ps.setString(4, month);
          //            add_ps.setInt(5, report_seq);
          //            add_rs = add_ps.executeQuery();
          //            if(add_rs.next()){
          //              wkey_seq = add_rs.getString(1);
          //            }
          //        } catch (Exception e) {
          //            SITLog.error(e, "\r\ngetting wkey_seq from sit_documents in _widgets.inc\r\n");
          //        } finally {
          //            try { add_rs.close(); } catch (Exception e) { } add_rs = null;
          //            try { add_ps.close(); } catch (Exception e) { } add_ps = null;
          //        }// try get key_seq 
//
          //        if(isDefined(wkey_seq)){
          //          try{ // get blob
          //              add_ps = add_conn.prepareStatement("select file_blob from sit_document_images where client_id=? and key_seq = ?");
          //              add_ps.setString(1, client_id);
          //              add_ps.setString(2, wkey_seq);
          //              add_rs = add_ps.executeQuery();
//
          //              if(add_rs.next()){
          //                Blob blob = add_rs.getBlob(1);
          //                FileOutputStream fos = null;
          //                try {
          //                  int b = 0;
          //                  InputStream is = blob.getBinaryStream();
          //                  fos = new FileOutputStream("/usr2/webtemp/" + aFileName);
          //                  while ((b = is.read()) != -1){ fos.write(b); }
          //                  Runtime.getRuntime().exec( "/usr/bin/chmod 666 /usr2/webtemp/" + aFileName );
          //                } catch (Exception e) {
          //                    SITLog.error(e, "\r\ngetting file_blob bytes in _widgets.inc\r\n");
          //                } finally {
          //                    try { fos.flush(); fos.close(); } catch (Exception e) {} fos = null;
          //                }
          //              } else {
          //                SITLog.warn("\r\nno file_blob in _widgets.inc\r\n");
          //              }
          //          } catch (Exception e) {
          //              SITLog.error(e, "\r\ngetting file_blob in _widgets.inc\r\n");
          //          } finally {
          //              try { add_rs.close(); } catch (Exception e) { }
          //              add_rs = null;
          //              try { add_ps.close(); } catch (Exception e) { }
          //              add_ps = null;
          //          }// try get blob 
          //        }//if isDefined(wkey_seq)
//
          //    } // end verify not finalized
          //      
//
} catch (Exception e) {
    SITLog.error(e, "Big outer for file link in _widgets");
} finally {
    try { add_conn.close(); } catch (Exception e) {} add_conn = null;
}   
          
        %>
          <div class="widget1" id="uploadFileWidget">
            <div class="wtitle">Upload File</div>
            <div id="uploadFile" style="padding: 12px 5px; text-align: center;">
              <form action="file_upload.jsp?upload=Y&report_seq=<%= report_seq %>" id="frmUpload" method="post" enctype="multipart/form-data">
                <div id="divUpload">
                  <input type="file" id="upload_file" name="upload_file" style="padding-left: 15px; width: 200px;"><br>
                  <button type="submit" id="btnUpload" style="margin-bottom: 15px;" disabled>Upload</button>
                </div>
                <div id="fileInfo"></div>
                <!-- <br>File uploaded?  -->
                <% //if (isDefined(wkey_seq)) {
                //      out.print("Yes - <a href=\"" + tempURL + aFileName + "\" target=\"_blank\">View File</a>");
                //    } else {
                //      out.print("No");
                //    }
                %>

              </form>
            </div>
        </div>
        <% } %>
      </div><!-- widgetWrangler -->