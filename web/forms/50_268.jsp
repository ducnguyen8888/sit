<%@ include file="../_configuration.inc"%><%--
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
    DN - 08/06/2018 - PRC 198588
        - Populated can in the 'Your Retailer License Number' field
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
%><script>
    // PRC 194604
    // Make sure that the top of statement is not pushed down when printing
	function Print(){
        window.onbeforeprint = function(){
            $("#container").css("margin-top","-70px");
        }
        
        window.onafterprint = function(){
             $("#container").css("margin-top","40px");
        }
        
        window.print();
    }
    
</script><%
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

    Connection connection = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

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
                    aprdistacc      = nvl(rs.getString(26));                
               }//while
			   
			   	// PRC 190387 retrieve appraisal district phone number using SIT client_pref which is only applied to Dallas
					if(client_id.equals("7580")){
						appraisalNumber = getSitClientPref(connection, ps, rs, client_id, "APPR_DIST_PHONE_SIT");
					}
            } catch (Exception e) {
                SITLog.error(e, "\r\nProblem getting dealers for 50_268.jsp\r\n");
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
                   sb.append("<tr><td style=\"width: 72px;\" class=\"dos\">" + nvl(rs.getString(1), "") + "</td>\r\n");
                   sb.append("    <td style=\"width: 48px;\" class=\"model\">" + nvl(rs.getString(2),"") + "</td>\r\n");
                   sb.append("    <td style=\"width:120px;\" class=\"make\">" + nvl(rs.getString(3), "") + "</td>\r\n");
                   sb.append("    <td style=\"width:138px;\" class=\"vin\">" + nvl(rs.getString(4), "") + "</td>\r\n");//2C3ABCBG1FH901234
                   sb.append("    <td style=\"width:153px;\" class=\"purchaser\">" + nvl(rs.getString(5), "") + "</td>\r\n");
                   sb.append("    <td style=\"width: 50px;\" class=\"type\">" + nvl(rs.getString(6), "") + "</td>\r\n");
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
                SITLog.error(e, "\r\nProblem getting sales for 50_268.jsp\r\n");
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
                    SITLog.error(e, "\r\nProblem getting totals for 50_268.jsp\r\n");
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
            try { connection.close(); } catch (Exception e) { }
            connection = null;
        }
    }// outer try  
}

start.append("<!DOCTYPE html>\r\n");
start.append("<HTML>\r\n");
start.append("<HEAD>\r\n");
start.append("    <META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\r\n");
start.append("    <TITLE>Form 50-268</TITLE>\r\n");
start.append("    <STYLE type=\"text/css\">\r\n");
start.append("        body {margin-top: 0px;margin-left: 0px;font:13px 'Arial'}\r\n");
start.append("        .page-holder { text-align: center; margin-top: 100px; }\r\n");
start.append("        button { width: 220px; margin: 0px 10px 10px 10px; }");
start.append("        #container { width: 778px; margin: 40px auto; text-align: left;}\r\n");
start.append("        #topImage { width: 778px; height: 120px; background-image: url(\"images/header.jpg\");}\r\n");
start.append("        #info1 p { margin-top: 5px; font: 10px 'Arial'; line-height: 12px;}\r\n");
start.append("        #licenseInfo { text-align: center; background: red; height: 40px; color: white; padding-top: 20px; margin-bottom: 10px; font-size: 14px; font-weight: bold; }\r\n");
start.append("	      #finalizeNotice { padding-top: 10px; padding-bottom: 10px;}");
start.append("\r\n");
start.append("        .finalForm { text-align: center; background: red;  color: white; font-size: 14px; font-weight: bold; }\r\n");
start.append("        .tg  {border-collapse:collapse;border-spacing:0;}\r\n");
start.append("        .tg td{font-family:Arial, sans-serif;font-size:12px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("        .tg th{font-family:Arial, sans-serif;font-size:12px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("        .tg .tg-k2ip{font-weight: bold; font-size: 10px; font-family:Arial, Helvetica, sans-serif !important; background-color: #e4ebf6; text-align: center; vertical-align: bottom;}\r\n");
start.append("        .tg .tg-yw4l{vertical-align:top}\r\n");
start.append("        #addlInstructions td {font: 12px 'Arial';}\r\n");
start.append("        #license { padding-left: 3px; letter-spacing: 2px; text-transform: uppercase; background: #FEFEAE; border-width: 1px; }\r\n");
start.append("\r\n");
start.append("        @media print {\r\n");
start.append("           #license {\r\n");
start.append("              border: none; background: none; padding-left: 0px;\r\n");
start.append("           }\r\n");
start.append("           .noprint{ display: none; }\r\n");
start.append("        }\r\n");
start.append("    </STYLE>\r\n");
start.append("</HEAD>\r\n");
start.append("<BODY>\r\n");

if (notDefined(request.getParameter("formSubmitted"))){
     // PRC 194604 Renamed button
    String buttonText = ("Y".equals(session.getAttribute("finalize_on_pay")) ? "Submit and Pay" : "Submit this Form to the Tax Office");
    middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
    middle.append("<div id=\"finalForm\" class=\"finalForm\">\r\n");
    // PRC 194604 Added red banner behind button
    middle.append("    <div id=\"finalizeNotice\">Your form has not been submitted. Please click "+ buttonText +"</div>\r\n");
    middle.append("    <form id=\"navigation\" action=\"\" method=\"post\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
    middle.append("      <input Type=\"hidden\" name=\"report_seq\" id=\"report_seq\" value=\"" + report_sequence + "\">\r\n");        
    middle.append("        <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
    middle.append("        <input type=\"hidden\" name=\"formSubmitted\" id=\"formSubmitted\" value=\"yes\">\r\n");
    middle.append("        <button type=\"submit\" id=\"finalizeIt\" name=\"finalizeIt\">"+buttonText+"</button>\r\n");
    middle.append("        <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
    //middle.append("    </form>\r\n");
    middle.append("  </div>\r\n");
    middle.append("</div>\r\n");
}else {
    middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
    // PRC 194604 updated the confirmatin notice
    if ("Y".equals(session.getAttribute("finalize_on_pay"))){
        middle.append("<div style=\"text-align: center; background: red;  color: white; ");
        middle.append("padding-top: 10px; font-size: 14px; font-weight: bold; height: 80px;\" class=\"noprint\">");
        middle.append("Your form has been submitted.<br>To complete the filing, you will need to make a payment.\r\n");
    }else{
        middle.append("<div style=\"text-align: center; background: red;  color: white; ");
        middle.append("padding-top: 10px; font-size: 14px; font-weight: bold; height: 95px;\" class=\"noprint\">");
        middle.append("Your form has been submitted.<br>"
                     +"Please print a copy to keep for your records and a copy to mail to the County Appraisal District.<br>"
                     +"You must go back to your Payments Due to submit your payment(s) to the Tax Office.\r\n");
    }
    middle.append("  <form id=\"navigation\" action=\"../confirmTotals.jsp\" method=\"post\">\r\n");
    middle.append("    <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
    middle.append("    <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
    middle.append("    <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
    middle.append("    <input Type=\"hidden\" name=\"report_seq\" id=\"report_seq\" value=\"" + report_sequence + "\">\r\n");        
    middle.append("    <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
    middle.append("    <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
    middle.append("    <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
    middle.append("      <br>");
    middle.append("    <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
	middle.append("    <button type=\"button\" id=\"print\" name=\"print\" onclick =\"Print()\">Print</button>\r\n");

    // PRC 194431 - 05/16/2018 - Harris County wants "Go to Cart" button to be displayed after the form is finalized
    if ( "Y".equals(session.getAttribute("finalize_on_pay"))
        || "2000".equals( client_id ) ){
        middle.append("    <button type=\"submit\" id=\"toCart\" name=\"toCart\">Go to Cart</button>\r\n");
    }  
    middle.append("  </form>\r\n<br>");
    middle.append("</div>\r\n");
    middle.append("</div>\r\n");
}

end.append("<div class= \"page-holder\">\r\n");
end.append("<div id=\"container\">\r\n");
end.append("<img src=\"images/50-268.png\" width=\"778\" alt=\"Inventory Tax Statement\" />\r\n");
end.append("<table style=\"float:right; padding:0px; margin:0px; margin-bottom: 10px;\">\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Phone <em>(area code and number)</em></td>\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Phone <em>(area code and number)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-268-1.png\" width=\"778\" style=\"margin: 10px 0px;\" alt=\"STEP 1: Owner's Name and Address\" />\r\n");




end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + uName + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + formatPhone(uPhone) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Owner's Name</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Phone <em>(area code and number)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uAddress1 + nvl(uAddress2) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Current Mailing Address <em>(number and street)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uCity + ", " + uState + " " + formatZip(uZipcode) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font: 9px 'Arial'; width: 550px;\">City, State, ZIP Code</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 200px;\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + uName + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + uTitle + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Person Completing Statement</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Title</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");


end.append("<img src=\"images/50-268-2.png\" width=\"778\" style=\"margin-top: 10px;\" alt=\"STEP 2: Information About the Business\" />\r\n");




end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">Give appraisal district account number if available or attach tax bill or copy of appraisal or tax office correspondence concerning your account.<br>If unavailable, give the street address at which the property is located.</p>\r\n");


end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">" +  dNameline1 + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Name of Each Business</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">" + aprdistacc + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Account Number</td>\r\n");
end.append("    </tr>    \r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">" + dAddress.toString() + ", " + dCity + ", " + dState + " " + dZipcode + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Inventory Location <em>(number, street, city, state, ZIP code + 4)</em></td>\r\n");
end.append("    </tr>\r\n");
end.append("</table>\r\n");


end.append("<img src=\"images/50-268-3.png\" width=\"778\" style=\"margin-top: 10px;\" alt=\"STEP 3: Inventory Information\" />\r\n");




end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">Provide the following information about each unit sold during the reporting month. Continue on additional pages if necessary.</p>\r\n");


end.append("<table id=\"inventory\" class=\"tg\" style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <th class=\"tg-k2ip\" colspan=\"4\">Description of Unit of Manufactured Housing Sold</th>\r\n");
end.append("    <th class=\"tg-k2ip\" rowspan=\"2\">Purchaser's Name</th>\r\n");
end.append("    <th class=\"tg-k2ip\">Type of<br>Sale<sup>1</sup></th>\r\n");
end.append("    <th class=\"tg-k2ip\">Sales<br>Price<sup>2</sup></th>\r\n");
end.append("    <th class=\"tg-k2ip\">Unit Property<br>Tax<sup>3</sup></th>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td class=\"tg-k2ip\">Date of<br>Sale</td>\r\n");
end.append("    <td class=\"tg-k2ip\">Model<br>Year</td>\r\n");
end.append("    <td class=\"tg-k2ip\">Make</td>\r\n");
end.append("    <td class=\"tg-k2ip\">Unit of Manufacturing<br>Housing Identification/<br>Serial Number</td>\r\n");
end.append("    <td class=\"tg-k2ip\" colspan=\"3\">(See last page for footnotes.)</td>\r\n");
end.append("  </tr>\r\n");
end.append("<!--loop loop loop -->\r\n");
end.append(sb.toString());
end.append("</table>\r\n");
end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + uptv + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n<td>");
// PRC 198588 - 08/06/2018 - populate can in the "Your Retailer License Number" field
end.append(nvl(request.getParameter("license"),"<input type=\"text\" id=\"license\" name=\"license\"style=\"width: 300px;\" value='"+ can +"' />\r\n")  );
end.append("  </td></tr>  \r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial'; width: 380px;\">Unit Property Tax Factor You Used</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Your Retailer License Number</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");


end.append("<img src=\"images/50-268-4.png\" width=\"778\" style=\"margin: 10px 0px;\" alt=\"STEP 4: Total Sales\" />\r\n");




end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("<tr>\r\n");
end.append("    <td colspan=\"5\" style=\"font: bold 11px 'Arial';\">Breakdown of sales (number of units sold) this month:</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"width: 250px;\">" + nvl(countMain, "0") + "</td>\r\n");
end.append("    <td style=\"width: 14px;\">&nbsp;</td>\r\n");
end.append("    <td style=\"width: 250px;\">" + nvl(countRL, "0") + "</td>\r\n");
end.append("    <td style=\"width: 14px;\">&nbsp;</td>\r\n");
end.append("    <td style=\"width: 250px;\">" + nvl(countSS, "0") + "</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Net Retail Manufacturing Housing Inventory</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Retailer Sales</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Subsequent Sales</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td colspan=\"5\" style=\"font: bold 11px 'Arial';\"><br>Breakdown of sales amounts for this month:</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td>" + nvl(amountMain, "$0.00") + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + nvl(amountRL, "$0.00") + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + nvl(amountSS, "$0.00") + "</td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Net Retail Manufacturing Housing Inventory</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Retailer Sales</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Subsequent Sales</td>\r\n");
end.append("</tr>\r\n");
end.append("</table>\r\n");


end.append("<img src=\"images/50-268-5.png\" width=\"778\" style=\"margin: 10px 0px;\" alt=\"STEP 5: Sign and Date the Statement on Last Page Only\" />\r\n");


end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("    <tr>\r\n");
end.append("        <td>" + uName + "</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td>" + uTitle + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial'; width: 550px;\">Print Name</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Title</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Authorized Signature</td>\r\n");
end.append("        <td></td>\r\n");
end.append("        <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Date</td>\r\n");
end.append("    </tr>\r\n");
end.append("</table>\r\n");


end.append("<p style=\"font: bold 10px 'Arial';\">If you make a false statement on this report, you could be found guilty of a Class A misdemeanor or a state jail felony under Penal Code Section 37.10.</p>\r\n");

end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" style=\"margin-top: 10px;\" />\r\n");

end.append("<div style=\"text-align:center;font: 32px 'Times New Roman';color: #0061a2; margin: 20px 0px;\">Instructions</div>\r\n");


end.append("<table id=\"addlInstructions\" style=\"width: 778px; padding:0px; margin:0px;text-align: justify;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 370px; vertical-align: top;\">\r\n");
end.append("      <table>\r\n");
end.append("        <tr>\r\n");
end.append("          <td colspan=\"2\">\r\n");
end.append("            If you are an owner of an inventory subject to Sec. 23.127, Tax Code, you must file this retail manufactured housing inventory tax statement as required by Sec. 23.128.\r\n");
end.append("            <p><strong>Filing deadlines:</strong> You must file this statement on or before the 10th day of each month regardless of whether a unit of manufactured housing is sold. If you were not in business for the entire year, you must file this statement each month after your business opens, but you do not include any tax payment until the beginning of the next calendar year. However, if your dealership was the purchaser of an existing dealership and you have a contract with the prior owner to pay the current year retail manufactured housing inventory taxes owed, then you must notify the chief appraiser and the county tax assessor-collector of this contract and continue to pay the monthly tax payment. Be sure to keep a completed copy of the statement for your files and a blank copy of the form for each month's filing.</p>\r\n");
end.append("            <p><strong>Filing places:</strong> You must file the original statement with your monthly tax payment with the county tax assessor-collector. You must file a copy of the original completed statement with the county appraisal district's chief appraiser.</p>\r\n");
end.append("            <p><strong>Filing penalties:</strong> Late filing incurs a penalty of 5 percent of the amount due. If the amount is not paid within 10 days after the due date, the penalty increases by an additional penalty of 5 percent of the amount due. Failure to file this form is a misdemeanor offense punishable by a fine not to exceed $100. Each day that you fail to comply is a separate offense. In addition, a tax lien attaches to your business personal property to secure the penalty's payment. The district attorney, criminal district attorney, county attorney, collector, or person designated by the collector shall collect the penalty, with action in the county in which you maintain your principal place of business or residence. You also will forfeit a penalty of $500 for each month or part of a month in which this statement is not filed after it is due.</p>\r\n");
end.append("            <p><strong>Annual property tax bill:</strong> You will receive a separate tax bill(s) for your manufactured housing inventory for each taxing unit that taxes your property, usually in October. The county tax assessor-collector also will receive a copy of the tax bill(s) and will pay each taxing unit from your escrow account. If your escrow account is not sufficient to pay the taxes owed, the county tax assessor-collector will send you a tax receipt for the partial payment and a tax bill for the amount of the deficiency. You must send to the county tax assessor-collector the balance of total tax owed. You may not withdraw funds from your escrow account.</p></td>\r\n");
end.append("        </tr>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top; width: 8px;\">&nbsp;</td>\r\n");
end.append("          <td><strong>Step 1:</strong> Owner's name and address. Give the corporate, sole proprietorship or partnership's name, including mailing address and telephone number of the actual business location required by the monthly statement (not of the owner). Give name and title of the person that completed the statement.\r\n");
end.append("<p><strong>Step 2:</strong> Information about the business. Give the address of the actual physical location of the business. Include your business' name and the account number from the appraisal district's notices.</p></td>\r\n");
end.append("        </tr>\r\n");
end.append("      </table>\r\n");
end.append("    </td>\r\n");
end.append("    <td style=\"vertical-align: top;\">\r\n");
end.append("      <table>\r\n");
end.append("        <tr>\r\n");
end.append("          <td colspan=\"2\"><strong>Step 3: Information on each unit of manufactured housing sold during the reporting month.</strong> Complete the information on each unit of manufactured housing sold, including the date of sale, model year, model make, manufactured home identification number, purchaser's name, type of sale, sales price and unit property tax. The footnotes include:</td>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top;\"><sup>1</sup></td>\r\n");
end.append("          <td>\r\n");
end.append("            <strong>Type of Sale:</strong> Place one of the following codes by each sale reported:\r\n");
end.append("            <p><strong>MH -- Retail manufactured housing inventory</strong> -- all units of manufactured housing held for sale at retail. A \"mobile home\" has the meaning assigned to that term by the Texas Manufactured Housing Standards Act (Occupations Code, Section 1201.003). A \"HUD-code manufactured home\" has the meaning assigned to that term by Section 3 of the Act. \"Manufactured housing\" is a HUD-code manufactured home or a mobile home as each would customarily be held by a retailer in the normal course of business in a retail manufactured housing inventory.</p>\r\n");
end.append("            <p><strong>RL -- retailer sales</strong> -- sales of manufactured housing to another retailer.</p>\r\n");
end.append("            <p><strong>SS -- subsequent sales</strong> -- retailer-financed sales of manufactured housing that, at the time of sale, have retailer financing from your manufactured housing inventory in this same calendar year. The first sale of a retailerfinanced house is reported as a manufactured housing inventory sale, with sale of this same house later in the year classified as a subsequent sale.</p>\r\n");
end.append("          </td>\r\n");
end.append("        </tr>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top; width: 8px;\"><sup>2</sup></td>\r\n");
end.append("          <td><strong>Sales Price:</strong> The total amount of money paid or to be paid to a retailer for the purchase of a unit of manufactured housing, excluding any amount paid for the installation of the home.</td>\r\n");
end.append("        </tr>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top;\"><sup>3</sup></td>\r\n");
end.append("          <td><strong>Unit Property Tax:</strong> To compute, multiply the sales price by the unit property tax factor. For retailer and subsequent sales that are not included in the net manufactured housing inventory, the unit property tax is $-0-. The unit property tax factor is the county aggregate tax rate divided by 12 and then by $100. Calculate your aggregate tax rate by adding the property tax rates for all taxing units in which the inventory is located. Use the property tax rates for the year preceding the year in which the unit is sold. If the county aggregate tax rate is expressed in dollars per $100 of valuation, divide by $100 and then divide by 12. Dividing the aggregate rate by 12 yields a monthly tax rate and by $100 to a rate per $1 of sales price.</td>\r\n");
end.append("        </tr>\r\n");
end.append("        <tr>\r\n");
end.append("          <td style=\"text-align: left; vertical-align: top;\"><sup>4</sup></td>\r\n");
end.append("          <td><strong>Total Unit Property Tax for This Month:</strong> Enter only on last page of monthly statement.</td>\r\n");
end.append("        </tr>  \r\n");
end.append("        <tr>\r\n");
end.append("          <td colspan=\"2\">\r\n");
end.append("            <strong>Step 4: Total sales.</strong> Provide totals on last page of monthly statement of the number of units and the sales amounts for manufactured housing sold in each category.\r\n");
end.append("            <p><strong>Step 5: Sign the form.</strong> Sign and enter the date if you are the person completing this statement.</p></td>\r\n");
end.append("        </tr>\r\n");
end.append("      </table></td>\r\n");
end.append("  </tr> \r\n");
end.append("</table>\r\n");


end.append("<div id=\"version\" style=\"text-align: right; font-style: italic; font-size: 10px;\">50-268 * 04-15/6</div>\r\n");
end.append("</div><!--container -->\r\n");
end.append("</div><!--page holder -->\r\n");

end.append("<script src=\"../assets/js/jquery.min.js\"></script> \r\n");
end.append("<script>\r\n");
end.append("    $(document).ready(function() {\r\n");
// PRC 194431 - 05/16/2018 - Harris County wants "Go to Cart" button to be displayed after the form is finalized
if ( "Y".equals(session.getAttribute("finalize_on_pay"))
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
    end.append("    </form>\r\n");    
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

if (isDefined(request.getParameter("formSubmitted"))){ 
  String thisPage = "50-268.jsp";
%><%@ include file="_monthly.jsp"%><%

}//if (isDefined(request.getParameter("formSubmitted")))

    try{
      out.print(start.toString() + middle.toString() + end.toString()); 
    } catch(Exception e){SITLog.error(e, "\r\nProblem writing StringBuffers for 50_268.jsp\r\n");} 

%>