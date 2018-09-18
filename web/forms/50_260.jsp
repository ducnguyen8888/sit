<%@ include file="../_configuration.inc"%>
<%--
    DN - 02/07/2018 - PRC 194604
        Renamed "Finalize and Pay" button to "Submit and Pay" button
        Renamed "Finalize this Form" button to "Submit this Form to Tax Office"
        Added the red banner behind submit button. It should say "Your form has not been submitted. Please click Submit this Form to the Tax Office"
        Updated the confirmation notice
    DN - 02/27/2018 - PRC 194604
        Adjust the statement margin-top with red banner
        Make sure that the top of statement is not pushed down when printing   
    DN - 05/16/2018 - PRC 194431
        Harris County wants the "Go to Cart" button to be displayed after the form is finalized even though Harris County is not "Finalized on Pay"
    DN - 06/15/2018 - PRC 194602
        - In case the start date in taxdtl table is null, the start date field will be left blank instead of  populating a made up start date
    DN - 08/06/2018 - PRC 198588
        - Populate can in the 'TPWD' field
    DN - 09/13/2018 - PRC 197579
        - Dont let the users to close the monthly statement if they have the "viewOnly" right.
--%><%! 
public StringBuffer getDealerAddress(Dealership d){
    StringBuffer sb = new StringBuffer();
    if (isDefined(d.nameline2)){sb.append(d.nameline2);}
    if (isDefined(d.nameline3)){sb.append(", " + d.nameline3);}
    if (isDefined(d.nameline4)){sb.append(", " + d.nameline4);}
    sb.append(", " + nvl(d.city) + ", " + nvl(d.state) + " " + formatZip(d.zipcode));
    //if (isDefined(d.phone)){sb.append("<br>Phone: " + formatPhone(d.phone));}
    return sb;
}
public String someSpaces(int i){
    StringBuffer sb = new StringBuffer();
    for (int x = 0; x < i; x++){
        sb.append("&nbsp;");
    }
    return sb.toString();
}
%>
<link href="../assets/css/jquery-ui.min.css" rel="stylesheet">
<script src="../assets/js/jquery.min.js"></script>
<script src="../assets/js/jquery-ui.min.js"></script> 
<script>
    // PRC 194604
    // Make sure that the top of statement is not pushed down when printing
    function Print(){
        window.onbeforeprint = function(){
            $("#container").css("margin-top","-70px");
        }
        
        window.onafterprint = function(){
             $("#container").css("margin-top","70px");
        }
        
        window.print();
    }
    
    
</script>
<%
StringBuffer start  = new StringBuffer();
StringBuffer middle = new StringBuffer();
StringBuffer end    = new StringBuffer();
String client_id    = (String) session.getAttribute( "client_id");
String userid       = (String) session.getAttribute( "userid");
String report_sequence = (isDefined(request.getParameter("report_seq"))) ? request.getParameter("report_seq") : "1"; // sit_sales_master
java.text.DecimalFormat df = new java.text.DecimalFormat("$###,###,###.00");

String dNameline1 = "";
String dNameline2 = "";
String dNameline3 = "";
String dNameline4 = "";
String dCity = "";
String dState = "";
String dCountry = "";
String dZipcode = "";
String dPhone = "";
StringBuffer dAddress = new StringBuffer();

String uName = "";
String uTitle = "";
String uAddress1 = "";
String uAddress2 = "";
String uCity = "";
String uState = "";
String uZipcode = "";
String uPhone = "";
StringBuffer uAddress = new StringBuffer();

String countDL = "";
String countFL = "";
String countMain = "";
String countSS = "";
String countRL = "";
String amountDL = "";
String amountFL = "";
String amountMain = "";
String amountSS = "";
String amountRL = "";

String appraisalName = "";
String appraisalNumber = "";
String countyName = "";
String countyAddress1 = "";
String countyAddress2 = "";
String countyNumber = "";
String todaysDate = "";

String uptv = "";
String aprdistacc = "";//named like the db field

StringBuffer sb = new StringBuffer();
if(request.getParameter("can") != null){

    PreparedStatement ps = null;
    ResultSet rs = null;
    Connection connection = null;

    connection = connect();
    month = month.length() == 1 ? "0" + month : month; // makes 7 = 07  
    if(request.getParameter("removeMe") != null && "yes".equals(request.getParameter("removeMe"))){
        payments.remove(can, year, month);
    }
    try{    
            try { // Step #1 get the dealer info          
                ps = connection.prepareStatement("select o.nameline1, o.nameline2, o.nameline3, o.nameline4, o.city, o.state, o.country, o.zipcode, o.phone,  "
                                              + "        u.name, u.title, u.address1, u.address2, u.city, u.state, u.zipcode, u.phone, "
                                              + "        cs.description, cs.other, a.name, a.address1, a.address2, a.phone, to_char(sysdate, 'MM/DD/YYYY'), "
                                              //+ "        ROUND(sit_get_uptv(?, ?, ?), 8), t.aprdistacc "  
                                              + "        act_subsystems.taxunit_monthly_rate(?,?,?), t.aprdistacc "                                            
                                              + " from sit_users u "
                                              + "    join sit_ownership_username ou on (ou.client_id = u.client_id and ou.userid = u.userid) "
                                              + "    join owner o on (o.client_id=ou.client_id and o.can=ou.can)  "
                                              + "    JOIN codeset cs on (cs.client_id = ou.client_id) "
                                              + "    JOIN jurisdiction a ON (ou.client_id = a.client_id) "
                                              + "    JOIN taxdtl t on (t.can = o.can)"
                                 //             + " where ou.client_id=? and ou.userid=? and ou.can=?  "
                                 //             + " and (ou.active is null or ou.active='Y') and o.year= ?");
                                              + "  WHERE u.client_id = ? AND u.userid = ? AND o.can= ? "
                                              + "     AND o.year = (select max(year) from owner WHERE can= ?) AND cs.code= ? "
                                              + "     AND a.taxunit = nvl(SIT_GET_CODESET_VALUE(?,'DESCRIPTION','CLIENT','PRIM_JURIS'),0) "
                                              + "     AND a.year = (select max(year) from jurisdiction b "
                                              + "                   where b.client_id = a.client_id "
                                              + "                     and b.taxunit = a.taxunit)"
                                              + "     AND t.year = (select max(year) from taxdtl WHERE can=?)");

                ps.setString(1, can);
                ps.setString(2, year);
                ps.setString(3, client_id);
                ps.setString(4, client_id);
                ps.setString(5, userid);
                ps.setString(6, can);
                ps.setString(7, can);
                ps.setString(8,"APPR_DIST");
                ps.setString(9, client_id);
                ps.setString(10, can);


                //ps.setString(1, client_id);
                //ps.setString(2, userid);
                //ps.setString(3, can);
                //ps.setString(4, year);
                rs = ps.executeQuery();

                if (rs.next()) {
                    dNameline1 = nvl(rs.getString(1));
                    dNameline2 = nvl(rs.getString(2));
                    dNameline3 = nvl(rs.getString(3));
                    dNameline4 = nvl(rs.getString(4));
                    dCity      = nvl(rs.getString(5));
                    dState     = nvl(rs.getString(6));
                    dCountry   = nvl(rs.getString(7));
                    dZipcode   = nvl(rs.getString(8));
                    dPhone     = nvl(rs.getString(9));
                    if (isDefined(dNameline2)) dAddress.append(dNameline2 + " ");
                    if (isDefined(dNameline3)) dAddress.append(dNameline3 + " ");
                    if (isDefined(dNameline4)) dAddress.append(dNameline4 + " ");
                    uName      = nvl(rs.getString(10));
                    uTitle     = nvl(rs.getString(11));
                    uAddress1  = nvl(rs.getString(12));
                    uAddress2  = nvl(rs.getString(13));
                    uCity      = nvl(rs.getString(14));
                    uState     = nvl(rs.getString(15));
                    uZipcode   = nvl(rs.getString(16));
                    uPhone     = nvl(rs.getString(17));
                    appraisalName   = nvl(rs.getString(18));
                    appraisalNumber = nvl(rs.getString(19));
                    countyName      = nvl(rs.getString(20));
                    countyAddress1  = nvl(rs.getString(21));
                    countyAddress2  = nvl(rs.getString(22));
                    countyNumber    = nvl(rs.getString(23));
                    todaysDate      = nvl(rs.getString(24));
                    uptv            = nvl(rs.getString(25));
                    aprdistacc     = nvl(rs.getString(26));
               }//while
               
               // PRC 190387 retrieve appraisal district phone number using SIT client_pref which is only applied to Dallas
                    if(client_id.equals("7580")){
                        appraisalNumber = getSitClientPref(connection, ps, rs, client_id, "APPR_DIST_PHONE_SIT");
                    }
              
            } catch (Exception e) {
                SITLog.error(e, "\r\nProblem getting dealer in 50-260.jsp.\r\n"); 
            } finally {
               try { rs.close(); } catch (Exception e) { }
               rs = null;
               try { ps.close(); } catch (Exception e) { }
               ps = null;
            }// try get dealerships

            try { // Step #1 get the dealer info          
                StringBuffer sqlStr = new StringBuffer();
                sqlStr.append("SELECT to_char(date_of_sale, 'mm/dd/yyyy'), model_year, make, vin_serial_no, ");
                sqlStr.append("       purchaser_name, sale_type, sales_price, tax_amount, 'X', sales_seq ");
                sqlStr.append("FROM sit_users u ");
                sqlStr.append("  JOIN sit_ownership_username o on ( o.client_id = u.client_id and o.userid = u.userid) ");
                sqlStr.append("  JOIN sit_sales s on (s.client_id = u.client_id and s.client_id = o.client_id and s.can = o.can) ");
                sqlStr.append("WHERE u.userid = ? AND s.CAN = ? AND s.year = ? AND s.month = ? AND s.status <> 'D' and s.report_seq=? ");
                sqlStr.append("ORDER BY date_of_sale desc ");
                
                ps = connection.prepareStatement(sqlStr.toString());
                ps.setString(1, userid);
                ps.setString(2, can);
                ps.setString(3, year);
                ps.setString(4, month);
                ps.setString(5, report_sequence);
                //SITLog.info("Form 246: userid: " + userid + ", can: " + can + ", year: " + year + ", month: " + month + ", report_sequence: " + report_sequence) ; 
                rs = ps.executeQuery();
                double sp  = 0.0; //sale price
                double td  = 0.0; //tax due
                double spT = 0.0; //total sale price
                double tdT = 0.0; //total tax due
                String fileDate = "";
                while(rs.next()) {
                   sp = Double.parseDouble(rs.getString(7));
                   spT += sp;
                   td = Double.parseDouble(rs.getString(8));
                   tdT += td;
                   fileDate = rs.getString(9);
                   sb.append("<tr><td style=\"width: 72px;\" class=\"dos\">" + rs.getString(1) + "</td>\r\n");
                   sb.append("    <td style=\"width: 48px;\" class=\"model\">" + rs.getString(2) + "</td>\r\n");
                   sb.append("    <td style=\"width:120px;\" class=\"make\">" + rs.getString(3) + "</td>\r\n");
                   sb.append("    <td style=\"width:138px;\" class=\"vin\">" + rs.getString(4) + "</td>\r\n");//2C3ABCBG1FH901234
                   sb.append("    <td style=\"width:153px;\" class=\"purchaser\">" + rs.getString(5) + "</td>\r\n");
                   sb.append("    <td style=\"width: 50px;\" class=\"type\">" + rs.getString(6) + "</td>\r\n");
                   sb.append("    <td style=\"width: 75px; text-align: right;\" class=\"price aRight\">" + df.format(sp) + "</td>\r\n");
                   sb.append("    <td style=\"width: 75px; text-align: right;\" class=\"tax aRight\">" + df.format(td) + "</td>\r\n");
                   //if (isDefined(fileDate) && !isFiled) isFiled = true;
                   //if (notDefined(fileDate)) sb.append("<td nowrap><i class=\"fa fa-pencil\"></i> <a href=\"#\" id=\"" + rs.getString(10) + "\">edit</a></td>\r\n");
                   sb.append("</tr>\r\n");
                }//while
                sb.append("    <tr>\r\n");
                sb.append("        <td colspan=\"7\" style=\"text-align: right; border: none;\">Total Unit Property<br>Tax this month<sup>4</sup></td>\r\n");
                sb.append("        <td style=\"text-align: right;\">" + df.format(tdT) + "</td>\r\n");
                sb.append("    </tr>\r\n");
            } catch (Exception e) {
                SITLog.error(e, "\r\nProblem getting totals in 50-260.jsp.\r\n"); 
            } finally {
               try { rs.close(); } catch (Exception e) { }
               rs = null;
               try { ps.close(); } catch (Exception e) { }
               ps = null;
            }// try get dealerships

            try { // Step #2 get summary info         
                StringBuffer sqlStr = new StringBuffer();
                sqlStr.append("select count(can), to_char(sum(sales_price), '$999,999,999.00') amount, sale_type");
                sqlStr.append(" from   sit_sales ");
                sqlStr.append(" where  can = ? and year=? and month=? and status <> 'D' and report_seq=? ");
            //if("MV".equals(category))   sqlStr.append(" AND form_name = '50-246' AND (sale_type = 'MV'  OR sale_type = 'FL' OR sale_type = 'DL' OR sale_type = 'SS') ");
            //if("HE".equals(category))   sqlStr.append(" AND form_name = '50-266' AND (sale_type = 'HE'  OR sale_type = 'FL' OR sale_type = 'DL' OR sale_type = 'SS') ");
            //if("VTM".equals(category))  sqlStr.append(" AND form_name = '50-260' AND (sale_type = 'VTM' OR sale_type = 'FL' OR sale_type = 'DL' OR sale_type = 'SS') ");
            //if("MH".equals(category))   sqlStr.append(" AND form_name = '50-268' AND (sale_type = 'MH'  OR sale_type = 'RL' OR sale_type = 'SS') ");// RS = retailer sales
                sqlStr.append(" group by sale_type");
                sqlStr.append(" order by sale_type");
                    ps = connection.prepareStatement(sqlStr.toString());
                                               //TODO: need to join with sit_users? But, I'm getting duplicates (fix: ensure all common fields are linked)
                                               //TODO: FL/DL/SS can be used with HE. Form is distinguishing factor
                    ps.setString(1, can);
                    ps.setString(2, year);
                    ps.setString(3, month);
                    ps.setString(4, report_sequence);
                    
                    rs = ps.executeQuery();

                    while (rs.next()){
                        if("DL".equals(rs.getString(3))){
                            countDL = rs.getString(1);
                            amountDL = rs.getString(2);
                        }else if("FL".equals(rs.getString(3))){
                            countFL = rs.getString(1);
                            amountFL = rs.getString(2);
                        }else if(category.equals(rs.getString(3))){
                            countMain = rs.getString(1);
                            amountMain = rs.getString(2);
                        }else if("SS".equals(rs.getString(3))){
                            countSS = rs.getString(1);
                            amountSS = rs.getString(2);
                        }else if("RL".equals(rs.getString(3))){
                            countRL = rs.getString(1);
                            amountRL = rs.getString(2);
                        }

                    }
               } catch (Exception e) {
                    SITLog.error(e, "\r\nProblem getting more totals in 50-260.jsp.\r\n"); 
               } finally {
                   try { rs.close(); } catch (Exception e) { }
                   rs = null;
                   try { ps.close(); } catch (Exception e) { }
                   ps = null;
               }// try get dealerships
        
    } catch (Exception e) {
    } finally {
        try { rs.close(); } catch (Exception e) { }
        rs = null;
        try { ps.close(); } catch (Exception e) { }
        ps = null;
        if (connection != null) {
            try { connection.close(); } catch (Exception e) { SITLog.error(e, "\r\nProblem closing connection in 50-260.jsp.\r\n"); }
            connection = null;
        }
    }// outer try  
}

start.append("<!DOCTYPE html>\r\n");
start.append("<HTML>\r\n");
start.append("<HEAD>\r\n");
start.append("<META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\r\n");
start.append("<TITLE>Form 50-260</TITLE>\r\n");
start.append("<STYLE type=\"text/css\">\r\n");
start.append("  body {margin-top: 0px;margin-left: 0px;font:13px 'Arial'}\r\n");
start.append("  .page-holder { text-align: center; margin-top: 100px; }\r\n");
start.append("  button { width: 220px; margin: 0px 10px 10px 10px; }");
start.append("  #container { width: 778px; margin: 70px auto; text-align: left;}\r\n");
start.append("  #topImage { width: 778px; height: 120px; background-image: url(\"images/header.jpg\");}\r\n");
start.append("  #info1 p { margin-top: 5px; font: 10px 'Arial'; line-height: 12px;}\r\n");
start.append("  #licenseInfo { text-align: center; height: 50px; background-color: red; color: white; padding-top: 10px; margin-bottom: 10px; font-size: 14px; font-weight: bold; }\r\n");
start.append("  #finalizeNotice { padding-top: 10px; padding-bottom: 10px;}");
start.append("  .finalForm { text-align: center; background: red;  color: white; font-size: 14px; font-weight: bold; }\r\n");
start.append("  .tg  {border-collapse:collapse;border-spacing:0;}\r\n");
start.append("  .tg td{font-family:Arial, sans-serif;font-size:12px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("  .tg th{font-family:Arial, sans-serif;font-size:12px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("  .tg .tg-k2ip{font-weight:bold;font-size:10px;font-family:Arial, Helvetica, sans-serif !important;background-color:#e4ebf6;text-align:center;vertical-align:bottom;}\r\n");
start.append("  .tg .tg-yw4l{vertical-align:top}\r\n");
start.append("  .breakIt { page-break-after: always; }\r\n");
start.append("  #addlInstructions td {font: 12px 'Arial';}\r\n");
start.append("  #tpwd { padding-left: 3px; letter-spacing: 2px; text-transform: uppercase; background: #FEFEAE; border-width: 1px; }\r\n");
start.append("  @media print {\r\n");
start.append("  #tpwd { border: none; background: none; padding-left: 0px; }\r\n");
start.append("  .noprint{ display: none; }\r\n");
start.append("  }\r\n");
start.append("  .fixedDialog{ position: fixed;} \r\n");
start.append("  </STYLE>\r\n");
start.append("</HEAD>\r\n");
start.append("<BODY>\r\n");

if (notDefined(request.getParameter("formSubmitted"))){
    // PRC 194604 Renamed button
    String buttonText = ("Y".equals(session.getAttribute("finalize_on_pay")) ? "Submit and Pay" : "Submit this Form to the Tax Office");
    middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
    middle.append("  <div id=\"finalForm\" class=\"finalForm\">\r\n");
    // PRC 194604 Added red banner behind button
    middle.append("    <div id=\"finalizeNotice\">Your form has not been submitted. Please click "+ buttonText +"</div>\r\n");
    middle.append("    <form id=\"navigation\" action=\"\" method=\"post\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
    middle.append("        <input Type=\"hidden\" name=\"report_seq\" id=\"report_seq\" value=\"" + report_sequence + "\">\r\n");    
    middle.append("        <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"formSubmitted\" id=\"formSubmitted\" value=\"yes\" >\r\n");
    middle.append("        <button type=\"button\" id=\"finalizeIt\" name=\"finalizeIt\">"+buttonText+"</button>\r\n");
    middle.append("        <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
    //middle.append("    </form>\r\n");
    middle.append("  </div>\r\n");
    middle.append("</div>\r\n");
  
}else {
    middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
    // PRC 194604 updated the confirmatin notice
    if ("Y".equals(session.getAttribute("finalize_on_pay"))){
        middle.append("  <div style=\"text-align: center; background: red;  color: white; ");
        middle.append("  padding-top: 10px; font-size: 14px; font-weight: bold; height: 80px;\" class=\"noprint\">");
        middle.append("Your form has been submitted.<br>To complete the filing, you will need to make a payment.\r\n");
    } else {
        middle.append("  <div style=\"text-align: center; background: red;  color: white; ");
        middle.append("  padding-top: 10px; font-size: 14px; font-weight: bold; height: 95px;\" class=\"noprint\">");
        middle.append("Your form has been submitted.<br>"
                     +"Please print a copy to keep for your records and a copy to mail to the County Appraisal District.<br>"
                     +"You must go back to your Payments Due to submit your payment(s) to the Tax Office.\r\n");
    }
    middle.append("    <form id=\"navigation\" action=\"../confirmTotals.jsp\" method=\"post\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
    middle.append("      <input Type=\"hidden\" name=\"report_seq\" id=\"report_seq\" value=\"" + report_sequence + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
    middle.append("      <br>");
    middle.append("      <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
    middle.append("      <button type=\"button\" id=\"print\" name=\"print\" onclick =\"Print()\">Print</button>\r\n");
    // PRC 194431 - 05/16/2018 - Harris County wants "Go to Cart" button to be displayed after the form is finalized
    if ( "Y".equals(session.getAttribute("finalize_on_pay" ))
        || "2000".equals( client_id ) ){
        middle.append("    <button type=\"submit\" id=\"toCart\" name=\"toCart\">Go to Cart</button>\r\n");
    }      
    middle.append("    </form>\r\n<br>");
    middle.append("  </div>\r\n");
  
    middle.append("</div>\r\n");    
}

middle.append("<div style=\"position: fixed;\">\r\n");
middle.append("<div id=\"operationWarning\">\r\n");
middle.append("<div style=\"text-align: center; font-weight: bold;\">\r\n");
middle.append("<div style=\"color: red;\">Warning!!</div><br>\r\n");
middle.append("Attempted to perform an unauthorized operation.\r\n");
middle.append("</div></div></div>\r\n");

end.append("<div class= \"page-holder\">\r\n");
end.append("<div id=\"container\">\r\n");
end.append(" <img src=\"images/50-260.png\" width=\"778\" alt=\"Inventory Tax Statement\" /> \r\n");

end.append("<table style=\"float: right; padding:0px; margin:0px; margin-bottom: 10px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width:80px;\">" + month + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width:80px;\">" + year + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Reporting Month</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Year</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">" + nvl(countyName) + " " + nvl(countyAddress1) + " " + nvl(countyAddress2) + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 150px;\">" + formatPhone(countyNumber) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Send Original to: County Tax Office Name and Address</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Phone (area code and number)</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + appraisalName + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + formatPhone(appraisalNumber) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Send Copy to: Appraisal District Name and Address</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Phone (area code and number)</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<div id=\"info1\" style=\"margin: 10px 0px;\">\r\n");
end.append("<p style=\"font: bold 10px 'Arial'; margin-bottom: 5px;\">This document must be filed with the county tax assessor-collector's office and the appraisal district office in the county in which your business is located. Do not file this document with the office of the Texas Comptroller of Public Accounts. Location and address information for the county tax assessor/collector's office in your county may be found at comptroller.texas.gov/propertytax/references/directory/tac. Location and address information for the appraisal district office in your county may be found at comptroller.texas.gov/propertytax/references/directory/cad.</p>\r\n");

end.append("<img src=\"images/lite-blue.png\" width=\"778\" height=\"6\"/>\r\n");
end.append("<p><strong>GENERAL INSTRUCTIONS:</strong> This inventory tax statement must be filed by a dealer of vessel and outboard motor inventory pursuant to Tax Code Section 23.125. This statement is filed together with an amount equal to the total amount of the unit property tax assigned to all vessels and outboard motors sold in the preceding month. File a separate statement for each business location and retain documentation.</p>\r\n");
end.append("<p><strong>WHERE TO FILE:</strong> This document and prepayment of taxes must be filed with the county tax assessor-collector's office. A copy of each statement must be filed with the appraisal district office.</p>\r\n");
end.append("<p><strong>STATEMENT DEADLINES:</strong> Except as provided by Tax Code Section 23.125(g), a statement and prepayment of taxes must be filed on or before the 10th day of each month.</p>\r\n");
end.append("<p><strong>PENALTIES:</strong> A dealer who fails to file or timely ile a statement commits a misdemeanor offense punishable by a ine not to exceed $100 with each day that the dealer fails to comply a separate violation. In addition to other penalties provided by law, a dealer who fails to file or timely file a statement must forfeit a penalty of $500 for each month or part of a month in which a statement is not filed or timely filed after it is due. A tax lien attaches to the dealer's business personal property to secure payment of the penalty. In addition to other penalties provided by law, an owner who fails to remit unit property tax due must pay a penalty of 5 percent of the amount due. If the amount due is not paid within 10 days after the due date, the owner must pay an additional 5 percent of the amount due. Unit property taxes paid on or before Jan. 31 of the year following the date on which they are due are not delinquent.</p>\r\n");
end.append("<p style=\"text-align: center;\"><strong>OTHER IMPORTANT INFORMATION:</strong></p>\r\n");
end.append("<p>The chief appraiser or collector may examine documents held by a dealer in the same manner and subject to the same conditions as provided by Tax Code Section 23.124(g) and 23.125(f).</p>\r\n");
end.append("</div>\r\n");
end.append("<img src=\"images/50-260-1.png\" alt=\"STEP 1: Dealer Information\" width=\"778\" />\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uName + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Name of Dealer</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uAddress1 + nvl(uAddress2) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Mailing Address</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + uCity + ", " + uState + " " + formatZip(uZipcode) + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + formatPhone(uPhone) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial'; width: 550px;\">City, State, ZIP Code</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Phone <em>(area code and number)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + uName + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + uTitle + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Name of Person Completing Statement</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Title</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-260-2.png\" alt=\"STEP 2: Business Location Information\" style=\"margin: 10px 0px;\" width=\"778\" />\r\n");

end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">Provide the appraisal district account number if available or attach a tax bill or copy of appraisal or tax office correspondence concerning your account.<br>Provide the dealer's and manufacturer's numbers issued by the Texas Parks and Wildlife Department (TPWD).</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">" +  dNameline1 + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Name of Business</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">" + dAddress.toString() + ", " + dCity + ", " + dState + " " + dZipcode + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Address, City, State, ZIP Code</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td>" + aprdistacc + "</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n        <td>");
// PRC 19858 - populate can in the 'TPWD' field
end.append(nvl(request.getParameter("tpwd"),"<input type=\"text\" id=\"tpwd\" name=\"tpwd\" style=\"width: 300px;\" value='"+ can +"'/>"));
end.append("</td>\r\n    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial'; width: 335px;\">Account Number</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">TPWD Dealer's and Manufacturer's Numbers</td>\r\n");
end.append("    </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-260-3.png\" alt=\"STEP 3: Inventory Information\" style=\"margin: 10px 0px;\" width=\"778\" />\r\n");

end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">Provide the following information about each vessel and outboard motor sale during the reporting month. Continue on additional pages if necessary. In lieu of filling out the information in this step, you may attach separate documentation setting forth the information required. All such information must be separately identiied in a manner that conforms to the column headers used in the table below. See last page for additional instructions and footnotes.</p>\r\n");

end.append("<table id=\"inventory\" class=\"tg\" style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <th class=\"tg-k2ip\" colspan=\"4\">Description of Vessel and Outboard Motor Sold</th>\r\n");
end.append("    <th class=\"tg-k2ip\" rowspan=\"2\">Purchaser's Name</th>\r\n");
end.append("    <th class=\"tg-k2ip\">Type of<br>Sale<sup>1</sup></th>\r\n");
end.append("    <th class=\"tg-k2ip\">Sales<br>Price<sup>2</sup></th>\r\n");
end.append("    <th class=\"tg-k2ip\">Unit Property<br>Tax<sup>3</sup></th>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td class=\"tg-k2ip\">Date of<br>Sale</td>\r\n");
end.append("    <td class=\"tg-k2ip\">Model<br>Year</td>\r\n");
end.append("    <td class=\"tg-k2ip\">Make</td>\r\n");
end.append("    <td class=\"tg-k2ip\">Identification Number</td>\r\n");
end.append("    <td class=\"tg-k2ip\" colspan=\"3\">(See last page for footnotes.)</td>\r\n");
end.append("  </tr>\r\n");
end.append("<!--loop loop loop -->\r\n");
end.append(sb.toString());
end.append("</table>\r\n");
end.append("<table style=\"width: 200px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + uptv + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial'; vertical-align: top;\">Unit Property Tax Factor</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-260-4.png\" alt=\"STEP 4: Units Sold and Sales Amount\" style=\"margin: 10px 0px;\" width=\"778\" />\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("<tr>\r\n");
end.append("    <td colspan=\"7\" style=\"font: bold 11px 'Arial';\">Breakdown Units Sold for Reporting Month:</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"width: 180px;\">" + nvl(countMain, "0") + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 180px;\">" + nvl(countFL, "0") + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 180px;\">" + nvl(countDL, "0") + "</td>\r\n");
end.append("    <td>&nbsp;</td>    \r\n");
end.append("    <td style=\"width: 180px;\">" + nvl(countSS, "0") + "</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Vessel and Outboard Motor Inventory</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Fleet Transactions</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Dealer Sales</td>\r\n");
end.append("    <td>&nbsp;</td>    \r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Subsequent Sales</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td colspan=\"5\" style=\"font: bold 11px 'Arial';\"><br>Breakdown of Sales Amounts for Reporting Month:</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td>" + nvl(amountMain, "$0.00") + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + nvl(amountFL, "$0.00") + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + nvl(amountDL, "$0.00") + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + nvl(amountSS, "$0.00") + "</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Vessel and Outboard Motor Inventory</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Fleet Transactions</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Dealer Sales</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Subsequent Sales</td>\r\n");
end.append("</tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-260-5.png\" alt=\"STEP 5: Signature\" style=\"margin: 10px 0px;\" width=\"778\" />\r\n");


end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("<tr>\r\n");
end.append("    <td>" + uName + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + uTitle + "</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial'; width: 550px;\">Print Name</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Title</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Authorized Signature</td>\r\n");
end.append("    <td></td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Date</td>\r\n");
end.append("</tr>\r\n");
end.append("</table>\r\n");

end.append("<p style=\"font: bold 10px 'Arial';\">If you make a false statement on this report, you could be found guilty of a Class A misdemeanor or a state jail felony under Penal Code Section 37.10.</p>\r\n");
end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" />\r\n");



end.append("<div style=\"text-align:center;font: 32px 'Times New Roman';color: #0061a2; margin: 20px 0px;\">Additional Instructions</div>\r\n");

end.append("<table id=\"addlInstructions\" style=\"width: 778px; padding:0px; margin:0px;text-align: justify;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 370px; vertical-align: top;\">\r\n");
end.append("      <table>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"vertical-align: top;\"><sup>1</sup></td>\r\n");
end.append("          <td style=\"padding-right: 5px;\">\r\n");
end.append("            <strong>Type of Sale:</strong> Place one of the following codes by each sale reported:\r\n");
end.append("            <p><strong>VM -- vessel and outboard motor inventory</strong> -- the sale of watercraft used or capable of being used for transportation on water that is not more than 65 feet in length (vessels) and the sale of self-contained internal combustion propulsion systems which are used to propel vessels and which are detachable as a unit from the vessel (outboard motors). The term \"vessel\" also includes a vehicle that is designed to carry watercraft and is either a \"trailer\" or \"semitrailer\" as defined by Transportation Code Section 501.002(23) and (29). The term \"vessel\" does not include watercraft of more than 65 feet in length; or a seaplane on water; or canoes, kayaks, punts, rowboats, rubber rafts, or other vessels under 14 feet in length when paddled, poled, oared, or windblown. This category does not include a fleet transaction, dealer sale, or subsequent sale, each of which is defined below. Only this type of sale has a unit property tax (see below). [See, Tax Code Sections 23.124(a)(8), (14), (15); and Parks and Wildlife Code, Section 31.003.]</p>\r\n");
end.append("            <p><strong>FL -- fleet transaction</strong> -- the sale of five or more vessels or outboard motors from a dealer's vessel and outboard motor inventory to the same business entity within one calendar year. [Tax Code Section 23.124(a)(7).]</p>\r\n");
end.append("            <p><strong>DL -- dealer sale</strong> -- the sale from a dealer's vessel and outboard motor inventory to another dealer, that is, a person who holds a dealer's and manufacturer's number issued by the Parks and Wildlife Department under the authority of Parks and Wildlife Code Section 31.041, or is authorized by law or interstate reciprocity agreement to purchase vessels or outboard</p></td>\r\n");
end.append("        </tr>\r\n");
end.append("\r\n");
end.append("      </table>\r\n");
end.append("    </td>\r\n");
end.append("    <td style=\"vertical-align: top;\">\r\n");
end.append("      <table>\r\n");
end.append("        <tr>\r\n");
end.append("          <td>&nbsp;</td>\r\n");
end.append("          <td>motors in Texas without paying the sales tax. The term does not include the manufacturer of vessels or outboard motors. [See, Tax Code Section 23.124(a)(3).]<p><strong>SS -- subsequent sale</strong> -- a dealer-financed sale of a vessel or outboard motor that, at the time of the sale, has been the subject of a dealer-inanced sale from the same dealer's vessel and outboard motor inventory in the same calendar year. [Tax Code Section 23.124(a)(12).]</p></td>\r\n");
end.append("        </tr>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top;\"><sup>2</sup></td>\r\n");
end.append("          <td>\r\n");
end.append("            <strong>Sales Price:</strong> The price as set forth on the \"Application for Texas Certiicate of Number/Title, for Boat/Seller, Donor or Trader's Affidavit\" for a vessel, the \"Application for Texas Certiicate of Title for an Outboard Motor/Seller, Donor or Trader's Affidavit\" for an outboard motor, or the \"Application for Texas Certiicate of Title\" for a trailer treated as a vessel, or the price that would appear if those forms were used.\r\n");
end.append("          </td>\r\n");
end.append("        </tr>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top; width: 8px;\"><sup>3</sup></td>\r\n");
end.append("          <td><strong>Unit Property Tax:</strong> To compute, multiply the sales price by the unit property tax factor. For fleet, dealer and subsequent sales that are not included in the vessel and outboard motor inventory, the unit property tax is $-0-. Contact either the county tax assessor-collector or county appraisal district for the current unit property tax factor. The unit property tax factor is calculated by dividing the prior year aggregate tax rate by 12. If the aggregate tax rate is expressed in dollars per $100 of valuation, divide by $100 and then divide by 12. It represents one-twelfth of the preceding year's aggregate tax rate at the location. If no unit property tax is assigned, state the reason.</td>\r\n");
end.append("        </tr>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top;\"><sup>4</sup></td>\r\n");
end.append("          <td><strong>Total Unit Property Tax for This Month:</strong> Enter the total amount of unit property tax. This is the total amount of unit property tax that will be submitted with the statement to the collector.</td>\r\n");
end.append("        </tr>\r\n");
end.append("      </table></td>\r\n");
end.append("  </tr> \r\n");
end.append("</table>\r\n");

end.append("<div id=\"version\" style=\"text-align: right; font-style: italic; font-size: 10px;\">50-260 * 05-15/10</div>\r\n");
end.append("</div><!--container -->\r\n");
end.append("</div><!--page holder -->\r\n");
    end.append("<script>\r\n");
    end.append("$(document).ready(function() {\r\n");
    end.append("$(this).scrollTop(0);");
    end.append("$(\"#operationWarning\").dialog({ \r\n");
    end.append("autoOpen: false,\r\n");
    end.append("open: function (event, ui) { $(\".ui-widget-overlay\").css({background: \"#000\", position:\"fixed\", top:\"0\", opacity: 0.7});$(\".ui-dialog\").css({ position: \"fixed\", top: \"250\"});},\r\n");
    end.append("    modal:true,\r\n");
    end.append("    width:500,");
    end.append("    buttons:[");
    end.append("        {");
    end.append("        text:\"OK\",");
    end.append("        width:\"100\",");
    end.append("        click: function() { $(this).dialog(\"close\"); $(document).scrollTop(0);}");
    end.append("        }");
    end.append("            ]");
    end.append(" });");
    end.append("$(\"#finalizeIt\").on(\"click\", function(e){\r\n");
    if ( !viewOnly ) {
        end.append("            var theForm = $(\"form#navigation\");\r\n");
        end.append("            theForm.submit();\r\n");
    } else {
        end.append("$(document).scrollTop(0);\r\n");
        end.append("$( \"#operationWarning\").dialog(\"open\");");
    }
    end.append("});");
    // PRC 194431 - 05/16/2018 - Harris County wants "Go to Cart" button to be displayed after the form is finalized
    if ( "Y".equals(session.getAttribute("finalize_on_pay" ))
        || "2000".equals( client_id ) ){
        end.append("        $(\"#toCart\").on(\"click\", function(e){ \r\n");
        end.append("            e.preventDefault();\r\n");
        end.append("            e.stopPropagation(); \r\n");
        end.append("            var theForm = $(\"form#navigation\");\r\n");
        end.append("            theForm.prop(\"action\", \"../pay.jsp\");\r\n");
        end.append("            theForm.submit();\r\n");
        end.append("        });\r\n"); 
    }       
    if (notDefined(request.getParameter("formSubmitted"))){
        end.append("        $(\"#goBack\").on(\"click\", function(e){ \r\n");
        end.append("            e.preventDefault();\r\n");
        end.append("            e.stopPropagation(); \r\n");
        end.append("            var theForm = $(\"form#navigation\");\r\n");
        end.append("            theForm.prop(\"action\", \"../confirmTotals.jsp\");\r\n");
        end.append("            theForm.submit();\r\n");
        end.append("        });\r\n");
    } 
    end.append("    });//doc ready\r\n");
    end.append("</script>    \r\n");

end.append("</BODY>\r\n");
end.append("</HTML>\r\n");


if (isDefined(request.getParameter("formSubmitted"))
        && !viewOnly){
  String thisPage = "50-260.jsp";
%>
  <%@ include file="_monthly.jsp"%>
<%

}//if (isDefined(request.getParameter("formSubmitted"))){





    try{
     out.print(start.toString() + middle.toString() + end.toString()); 
    } catch(Exception e){
      SITLog.error(e, "\r\nProblem outputting page in 50-260.jsp.\r\n"); 
    } 

%>