<%@ include file="_configuration.inc"%>
<%
    try{String thiscan =  "";
    String thisyear =  "";
    String thismonth =  ""; 
    String thisaction =  ""; 
    String thisReportSeq =  ""; 
    String thisClient = (String) session.getAttribute( "client_id");
    thiscan   = nvl(request.getParameter("can"));
    thisyear  = nvl(request.getParameter("year"));
    thismonth = nvl(request.getParameter("month"));
    thisaction = nvl(request.getParameter("action"));
    thisReportSeq = nvl(request.getParameter("report_seq"), "1");

    if(isDefined(thisaction)) {
        if ("remove".equals(thisaction)){
            payments.remove(thiscan, thisyear, thismonth);
        } 
        if("add".equals(thisaction) && !(payments.isInCart(can, year, month))){

            String totals = nvl(request.getParameter("totals"));
            String minPay = nvl(request.getParameter("minPay"));
            String [] monthsText = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
            String description   =  (monthsText[Integer.parseInt(thismonth)] + " " + thisyear);

            //if client_pref, get max(report_seq). 
            if (finalize_on_pay) {
                //If all are finalized, set to 0
                Connection connection = null;
                PreparedStatement ps = null;
                ResultSet rs = null;
                try { // check to see if this has been finalized
                    connection = connect();
                    ps = connection.prepareStatement("select max(report_seq) maxRS, sum(decode(report_status, 'C' , 1, decode(report_status, 'I' , 1, 0))) totalFinalized "
                                                   + "FROM   sit_sales_master  "
                                                   + "WHERE  client_id=? and can=? and year=? and month=?");
                    ps.setString(1, thisClient);
                    ps.setString(2, thiscan);
                    ps.setString(3, thisyear);
                    ps.setString(4, thismonth);
                    rs = ps.executeQuery();
                    if(rs.next()){
                        // if totalFinalized == maxRS
                        //      then all are finalized and report_seq should be 0
                        // else
                        //      report_seq = max(report_seq)
                        thisReportSeq = (rs.getInt(1) == rs.getInt(2) || rs.getInt(2) == 0) ? "0"  : rs.getString(1) ;
                    }
                } catch (Exception e) { 
                    SITLog.error(e, "\r\nProblem getting file date, report status, and finalize date in __getStatement.jsp\r\n");
                } finally {
                    try { rs.close(); } catch (Exception e) { }
                    rs = null;
                    try { ps.close(); } catch (Exception e) { }
                    ps = null;
                    try { connection.close(); } catch (Exception e) { }
                    connection = null;
                } // check to see if this has been finalized                
            }// if (client_pref)
            //       can   reportSeq  year  month   description   amountDue    amountPending    paymentAmount    minPayPayment    maxPayment
            payments.add(new Payment(thiscan,thisReportSeq, thisyear, thismonth, description, totals, "0.0", totals, minPay, "0.00"));
            //payments.add(new Payment("H000001", "1", "2016", "04", "April 2016", "1000.00", "0.0", "1000.00", "1000.00", "0.00"));
        }//if action == add
    }// if(isdefined(action))
    out.print ("{\"status\" : \"success\"}");
}catch(Exception e){out.print("Exception: " + e.toString());}
%>