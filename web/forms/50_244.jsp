<%@ include file="../_configuration.inc"
%><%--
    DN - 12/1/2017 -PRC 194344
        - Don't let the dealer information under attachment section to be automatically populated
    DN - 02/07/2018 - PRC 194604
        - Renamed "Finalize this Form" button to "Submit this Form to Tax Office"
        - Added the red banner behind submit button. It should say "Your form has not been submitted. Please click Submit this Form to the Tax Office"
        - Updated the confirmation notice
    DN - 2/14/2018 - PRC 195488
        - Only apply to Dallas County
        - If the account has the imported months, number of sold units, and sales amount will be the user's input instead of retrieving from database
    DN - 02/27/2018 - PRC 194604
        - Adjust the statement margin-top with red banner
        - Make sure that the top of statement is not pushed down when printing
    DN - 03/19/2018 - PRC 195488
        - Added hidden fields for users'input
    DN - 05/30/2018 - PRC 194602
        For 2017, the "Date Business Opened" or "Business Start Date" will be value in  "Start_Date" colum(taxdtl table).
        If this value is null in table, the "Date Business Opened" or "Business Start Date" will be set by default "1/1"+ selected year
        From 2018, the "Date Business Opened" or "Business Start Date" will be left blank    
    DN - 06/06/2018 - PRC 194602
        Form wil be submitted without filling the fields
    DN - 06/15/2018 - PRC 194602
        In case the start date in taxdtl table is null, the start date field will be left blank instead of  populating a made up start date
    DN - 08/06/2018 - PRC 198588
        Updated the logic, declarationYear = declarationYear +1 if "ANNUAL_DECLARATION_YEAR" sit pref value = 1
    
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

%><script>
   function Print(){
        window.onbeforeprint = function(){
            document.getElementById("container").style.marginTop = "-70px";
        }
        
        window.onafterprint = function(){
            document.getElementById("container").style.marginTop = "30px";
        }
      window.print();
    }
	
</script><%
StringBuffer start = new StringBuffer();
StringBuffer middle = new StringBuffer();
StringBuffer end = new StringBuffer();
String client_id = (String) session.getAttribute( "client_id" );
String userid = (String) session.getAttribute( "userid" );

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
String aprdistacc = "";//named like the db field

// PRC 195488 get number of sold units and sales amount from user's input
boolean importedMonths          = ( "true".equals(request.getParameter("importedMonths")) );

String  invCount                = sanitizeNumber(request.getParameter("invCount"));
String  invAmount               = sanitizeNumber(request.getParameter("invAmount"));

String  rsCount                 = sanitizeNumber(request.getParameter("rsCount"));
String  rsAmount                = sanitizeNumber(request.getParameter("rsAmount"));

String  fsCount                 = sanitizeNumber(request.getParameter("fsCount"));
String  fsAmount                = sanitizeNumber(request.getParameter("fsAmount"));

String  dsCount                 = sanitizeNumber(request.getParameter("dsCount"));
String  dsAmount                = sanitizeNumber(request.getParameter("dsAmount"));

String  ssCount                 = sanitizeNumber(request.getParameter("ssCount"));
String  ssAmount                = sanitizeNumber(request.getParameter("ssAmount"));

String priorTotal               = sanitizeNumber(request.getParameter("priorTotal"));
String market                   = sanitizeNumber(request.getParameter("market"));

String startDate                = "";
int    declarationYear          = nvl( year, 0 );


StringBuffer sb = new StringBuffer();
sb.append("client_id  is " + client_id + "<br>");
sb.append("userid is " + userid + "<br>");
sb.append("can param is " + request.getParameter("can") + "<br>");
sb.append("can variab is " + request.getParameter("can") + "<br>");

if(request.getParameter("can") != null){
    PreparedStatement       ps          = null;
    ResultSet               rs          = null;
    Connection              connection  = null;

    connection  = connect();
    // PRC 194602 - 06/15/2018 -  In case the start date in taxdtl table is null, the start date field will be left blank instead of  populating a made up start date 
    startDate       = getStartDate( connection, ps, rs, client_id, can , year );
    if ( isDefined( startDate ) ) {
        startDate   = dateFormat( convertToDate( startDate ) );
    }
    
     
    // PRC 198588 - 08/06/2018 - declarationYear = declarationYear +1 if "ANNUAL_DECLARATION_YEAR" sit codeset value = 1
    if ( "1".equals( getSitClientPref(connection, ps, rs, client_id, "ANNUAL_DECLARATION_YEAR") ) ) {
        declarationYear = declarationYear + 1;
    }
   
    try{    
            try { // Step #1 get the dealer info          
                ps = connection.prepareStatement("select o.nameline1, o.nameline2, o.nameline3, o.nameline4, o.city, o.state, o.country, o.zipcode, o.phone,  "
                                              + "        u.name, u.title, u.address1, u.address2, u.city, u.state, u.zipcode, u.phone, "
                                              + "        cs.description, cs.other, a.name, a.address1, a.address2, a.phone, to_char(sysdate, 'MM/DD/YYYY'), t.aprdistacc "
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

                ps.setString(1, client_id);
                ps.setString(2, userid);
                ps.setString(3, can);
                ps.setString(4, can);
                ps.setString(5,"APPR_DIST");
                ps.setString(6, client_id);
                ps.setString(7, can);




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
                    aprdistacc      = nvl(rs.getString(25));
               }//while
			   	// PRC 190387 retrieve appraisal district phone number using SIT client_pref which is only applied to Dallas
					if(client_id.equals("7580")){
						appraisalNumber = getSitClientPref(connection, ps, rs, client_id, "APPR_DIST_PHONE_SIT");
					}
            } catch (Exception e) {
                SITLog.error(e, "\r\nProblem getting dealers for 50_244.jsp\r\n");
                out.println(e.toString());
            } finally {
               try { rs.close(); } catch (Exception e) {  }
               rs = null;
               try { ps.close(); } catch (Exception e) {  }
               ps = null;
            }// try get dealerships

            try { // Step #1 get the dealer info          
            StringBuffer sqlStr = new StringBuffer();
            sqlStr.append("select count(can), to_char(sum(sales_price), '$999,999,999.00') amount, sale_type");
            sqlStr.append(" from   sit_sales ");
            sqlStr.append(" where  can = ? and year=? and status <> 'D' ");
            sqlStr.append(" group by sale_type");
            sqlStr.append(" order by sale_type");
                ps = connection.prepareStatement(sqlStr.toString());
                                           //TODO: need to join with sit_users? But, I'm getting duplicates (fix: ensure all common fields are linked)
                                           //TODO: FL/DL/SS can be used with HE. Form is distinguishing factor
                
                ps.setString(1, can);
                ps.setInt(2, Integer.parseInt(year));
                //ps.setInt(3, Integer.parseInt(month));
                
                
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
                SITLog.error(e, "\r\nProblem getting totals for 50_244.jsp\r\n");
           } finally {
               try { rs.close(); } catch (Exception e) {  }
               rs = null;
               try { ps.close(); } catch (Exception e) { }
               ps = null;
           }// try get dealerships
    } catch (Exception e) {
    } finally {
        try { rs.close(); } catch (Exception e) {   }
        rs = null;
        try { ps.close(); } catch (Exception e) {  }
        ps = null;
        if (connection != null) {
            try { connection.close(); } catch (Exception e) {  }
            connection = null;
        }
    }// outer try  
}

start.append("<!DOCTYPE html>\r\n");
start.append("<HTML>\r\n");
start.append("<HEAD>\r\n");
start.append("<META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\r\n");
start.append("<TITLE>Form 50-244</TITLE>\r\n");
start.append("<STYLE type=\"text/css\">\r\n");
start.append("  body {margin-top: 0px;margin-left: 0px;font-size: 9.75pt; font-family: Arial;}\r\n");
start.append("  .page-holder { text-align: center; margin-top: 100px; }\r\n");
start.append("  button { width: 220px; margin: 0px 10px 10px 10px; }");
start.append("  #container { width: 778px; margin: 30px auto; font-family: Arial; font-size: 9pt;}\r\n");
start.append("  #topImage { width: 778px; height: 120px; background-image: url(\"images/header.jpg\");}\r\n");
start.append("  #info1 p { margin-top: 5px; font-size: 7.5pt; font-family: Arial; line-height: 12px;}\r\n");
start.append("  #finalizeIt { margin-bottom: 10px;}");
start.append("  #finalizeNotice { padding-top: 10px; padding-bottom: 10px;}");
start.append("  .finalForm { text-align: center; background: red;  color: white; font-size: 14px; font-weight: bold; }\r\n");
start.append("  .tg  {border-collapse:collapse;border-spacing:0;}\r\n");
start.append("  .tg td{font-family:Arial, sans-serif;font-size:9pt;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("  .tg th{font-family:Arial, sans-serif;font-size:9pt;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("  .tg .tg-k2ip{font-weight:bold;font-size:7.5pt;font-family:Arial !important;background-color:#e4ebf6;text-align:center;vertical-align:bottom;}\r\n");
start.append("  .tg .tg-yw4l{vertical-align:top}\r\n");
start.append("  .breakIt { page-break-after: always; }\r\n");
start.append("  #addlInstructions td {font-size: 9pt; font-family: 'Arial';}\r\n");
start.append("  #tpwd { padding-left: 3px; letter-spacing: 2px; text-transform: uppercase; background: #FEFEAE; border-width: 1px; }\r\n");
start.append("  @media print {\r\n");
start.append("     #tpwd { border: none; background: none; padding-left: 0px; }\r\n");
start.append("     .noprint{ display: none; }\r\n");
start.append("  }\r\n");
start.append("  </STYLE>\r\n");
start.append("</HEAD>\r\n");
start.append("<BODY>\r\n");

if ( notDefined( request.getParameter("formSubmitted") ) ){
    middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
    middle.append("  <div id=\"finalForm\" class=\"finalForm\">\r\n");
    // PRC 194604 add red banner and text
    middle.append("    <div id=\"finalizeNotice\">Your form has not been submitted. Please click Submit this Form to the Tax Office</div>\r\n");
    middle.append("      <form id=\"navigation\" action=\"\" method=\"post\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"declarationYear\" id=\"declarationYear\" value=\"" + declarationYear+ "\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
    middle.append("          <input type=\"hidden\" name=\"formSubmitted\" id=\"formSubmitted\" value=\"yes\" >\r\n");
    // PRC 195488 get number of sold units and sales amount from user's input  
    middle.append("        <input type=\"hidden\"  name=\"importedMonths\" id=\"importedMonths\" value=\"" + importedMonths + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"invCount\" id=\"invCount\" value=\"" + invCount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"invAmount\" id=\"invAmount\" value=\"" + invAmount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"rsCount\" id=\"rsCount\" value=\"" + rsCount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"rsAmount\" id=\"rsAmount\" value=\"" + rsAmount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"fsCount\" id=\"fsCount\" value=\"" + fsCount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"fsAmount\" id=\"fsAmount\" value=\"" + fsAmount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"dsCount\" id=\"dsCount\" value=\"" + dsCount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"dsAmount\" id=\"dsAmount\" value=\"" + dsAmount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"ssCount\" id=\"ssCount\" value=\"" + ssCount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"ssAmount\" id=\"ssAmount\" value=\"" + ssAmount + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"priorTotal\" id=\"priorTotal\" value=\"" + priorTotal + "\">\r\n");
    middle.append("        <input type=\"hidden\"  name=\"market\" id=\"market\" value=\"" + market + "\">\r\n");
    // PRC 194604 rename button
    middle.append("        <button type=\"submit\" id=\"finalizeIt\" name=\"finalizeIt\">Submit this Form to the Tax Office</button>\r\n");
    middle.append("          <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
   // middle.append("      </form>\r\n");
    middle.append("    </div>\r\n");
    middle.append("</div>\r\n");
}else {
    middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
    middle.append("  <div style=\"text-align: center; background: red;  color: white; padding-top: 10px; font-size: 14px; font-weight: bold; height: 80px;\" class=\"noprint\">\r\n");
    //PRC 194604 updated the confirmation notice
    middle.append("Your form has been submitted.<br>Please print a copy to keep for your records and a copy to mail to the Appraisal District.\r\n");
    middle.append("    <form id=\"navigation\" action=\"../annualDeclaration.jsp\" method=\"post\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
    middle.append("      <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
    middle.append("      <br>\r\n");
    middle.append("      <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
	middle.append("    <button type=\"button\" id=\"print\" name=\"print\" onclick =\"Print()\">Print</button>\r\n");
    middle.append("    </form><br>\r\n");
    middle.append("  </div>\r\n");
    middle.append("</div>\r\n");
}

end.append("<div class= \"page-holder\">\r\n");
end.append("<div id=\"container\">\r\n");
end.append("<img src=\"images/50-244.png\" alt=\"Inventory Declaration\" width=\"778\" />\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 150px;\">" + declarationYear + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Year</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">" + nvl(countyName) + " " + nvl(countyAddress1) + " " + nvl(countyAddress2) + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 150px;\">" + formatPhone(countyNumber) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Send Original to: County Tax Office Name and Address</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Phone <em>(area code and number)</em></td>\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Send Copy to: Appraisal District Name and Address</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Phone <em>(area code and number)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<div id=\"info1\" style=\"margin: 10px 0px;\">\r\n");
end.append("<p style=\"font: bold 10px 'Arial'; margin-bottom: 5px;\">This document must be filed with the appraisal district office and the county tax assessor-collector's office in the county in which your business is located. Do not file this document with the office of the Texas Comptroller of Public Accounts. Location and address information for the appraisal district office in your county may be found at comptroller.texas.gov/propertytax/references/directory/cad. Location and address information for the county tax assessor-collector's office in your county may be found at comptroller.texas.gov/propertytax/references/directory/tac.</p>\r\n");
end.append("<img src=\"images/lite-blue.png\" width=\"778\" height=\"6\" />\r\n");

end.append("<p><strong>GENERAL INSTRUCTIONS:</strong> This declaration is for a dealer of motor vehicles to declare motor vehicle inventory pursuant to Tax Code Section 23.121. File a declaration for each business location.</p>\r\n");
end.append("<p><strong>ALTERNATIVE ELECTION:</strong> Effective Jan. 1, 2014, certain dealers of motor vehicle inventory may elect to file renditions under Tax Code Chapter 22, rather than file declarations and tax statements under Tax Code Chapter 23. Tax Code Section 23.121(a)(3) allows a dealer to make this election if it (1) does\r\n");
end.append("not sell motor vehicles that are self-propelled and designed to transport persons or property on a public highway; (2) meets either of the following two requirements: (a) the total annual sales from the inventory, less sales to dealers, fleet transactions, and subsequent sales, for the preceding tax year are\r\n");
end.append("25% or less of the dealer's total revenue from all sources during that period, or (b) the dealer did not sell a motor vehicle to a person other than another dealer during the preceding tax year and the dealer estimates that the dealer's total annual sales from the dealer's motor vehicle inventory, less sales to dealers, fleet transactions, and subsequent sales, for the 12-month period corresponding to the current tax year will be 25% or less of the dealer's total revenue from all sources during that period; (3) files with the chief appraiser and the tax collector by Aug. 31 of the tax year preceding Jan. 1 on a form prescribed by the Comptroller a declaration that the dealer elects not to be treated as a dealer under Tax Code Section 23.121 in the current tax year; AND\r\n");
end.append("(4) renders the dealer's motor vehicle inventory in the current tax year by filing a rendition with the chief appraiser in the manner provided by Tax Code\r\n");
end.append("Chapter 22. A dealer who makes this election must file the election annually with the chief appraiser and the tax collector by Aug. 31 of the preceding tax year, so long as the dealer meets the eligibility requirements of law.</p>\r\n");
end.append("<p><strong>WHERE TO FILE:</strong> Each declaration must be filed with the county appraisal district's chief appraiser and a copy of each declaration must be filed with the collector.</p>\r\n");
end.append("<p><strong>DECLARATION DEADLINES:</strong> Except as provided by Tax Code Section 23.122(l), a declaration must be filed not later than Feb. 1 of each year or, in the case of a dealer who was not in business on Jan. 1, not later than 30 days after commencement of the business. A dealer is presumed to have commenced business on the date of issuance of a dealer's general distinguishing number as provided by Transportation Code Chapter 503. Notwithstanding this presumption, a chief appraiser may, at his or her sole discretion, designate another date on which a dealer commenced business.</p>\r\n");
end.append("<p><strong>PENALTIES:</strong> A dealer who fails to file or timely ile a statement commits a misdemeanor offense punishable by a ine not to exceed $100 with each day that the dealer fails to comply a separate violation. In addition to other penalties provided by law, a dealer who fails to file or timely file a statement must forfeit a penalty of $500 for each month or part of a month in which a statement is not filed or timely filed after it is due. A tax lien attaches to the dealer's business personal property to secure payment of the penalty. In addition to other penalties provided by law, an owner who fails to remit unit property tax due must pay a penalty of 5 percent of the amount due. If the amount due is not paid within 10 days after the due date, the owner must pay an additional 5 percent of the amount due. Unit property taxes paid on or before Jan. 31 of the year following the date on which they are due are not delinquent.</p>\r\n");
end.append("<p style=\"text-align: center;\"><strong>OTHER IMPORTANT INFORMATION:</strong></p>\r\n");
end.append("<p>The chief appraiser may examine the books and records of a dealer as provided by Tax Code Section 23.121(g).</p>\r\n");
end.append("</div>\r\n");
end.append("<img src=\"images/50-244-1.png\" width=\"778\" alt=\"STEP 1: Dealer Information\" style=\"margin-bottom: 10px;\" />\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uName + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Name of Dealer</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uAddress1 + nvl(uAddress2) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Mailing Address</td>\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">City, State, ZIP Code</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Phone <em>(area code and number)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">&nbsp;</td>\r\n");
end.append("    <td style=\"width: 30px;\">&nbsp;</td>\r\n");
end.append("    <td style=\"width: 140px;\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  </table>\r\n");
end.append("  <table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td>" + uName + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>" + uTitle + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Name of Person Completing Statement</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Title</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<div class=\"breakIt\"></div>\r\n");
end.append("<img src=\"images/50-244-2.png\" width=\"778\" alt=\"STEP 2: All Business Locations and General Distinguishing Numbers\" style=\"margin-top: 10px;\"/>\r\n");


end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">Attach a list with the name and business address of each location at which you conduct business and each of the dealer's general distinguishing numbers issued by the Texas Department of Motor Vehicles.</p>\r\n");

end.append("<img src=\"images/50-244-3.png\" width=\"778\" alt=\"STEP 3: Business Location Information\" style=\"margin-top: 10px;\"/>\r\n");


end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">Provide the business name, general distinguishing number, physical address of the business location and account number for the inventory being declared or you may attach a tax bill or a copy of appraisal or tax office correspondence concerning your account.</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("    <tr>\r\n");
end.append("        <td>" +  dNameline1 + "</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td>" + can + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt; width: 550px;\">Name of Business</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
//PRC 194602 - 05/30/2018  Updated so it will match the 50-244 form in the Comptroller�s website
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">General Distinguishing Number of Location</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">" + dAddress.toString() + ", " + dCity + ", " + dState + " " + dZipcode + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\" colspan=\"3\">Address, City, State, ZIP Code</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td>" + aprdistacc + "</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
//PRC 194602 - 05/30/2018 Modified the logic how the value is set in  the "Date Business Opened" or "Business Start Date" field
if ("2017".equals( year) ) {
    end.append("        <td>" + startDate + "</td>\r\n");
} else {
    end.append("        <td>&nbsp;</td>\r\n");
}
end.append("</tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt; width: 550px;\">Account Number</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
//PRC 194602 - 05/30/2018  Updated so it will match the 50-244 form in the Comptroller�s website
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Business Start Date, if Not in Business on Jan 1</td>\r\n");
end.append("    </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-244-4.png\" width=\"778\" alt=\"STEP 4: Number of Units Sold and Sale Totals\" />\r\n");



end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"7\" style=\"font-family: Arial; font-size: 8.25pt; padding: 10px 0px;\">Number of units sold for the previous 12-month period corresponding to the prior tax year. If you were not in business for the entire 12-month period, report the sales for the months you were in business. See the last page for additional instructions.</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
// PRC 195488 if the account has the imported months, the populated data will be from user's input, otherwise the populated data will be retrieved from database
if ( !importedMonths ) {
    end.append("      <td style=\"width: 180px;\">" + nvl(countMain, "0") + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td style=\"width: 180px;\">" + nvl(countFL, "0") + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td style=\"width: 180px;\">" + nvl(countDL, "0") + "</td>\r\n");
    end.append("      <td>&nbsp;</td>    \r\n");
    end.append("      <td style=\"width: 180px;\">" + nvl(countSS, "0") + "</td>\r\n");
} else {
    end.append("      <td style=\"width: 180px;\">" + invCount+ "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td style=\"width: 180px;\">" + fsCount + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td style=\"width: 180px;\">" + dsCount + "</td>\r\n");
    end.append("      <td>&nbsp;</td>    \r\n");
    end.append("      <td style=\"width: 180px;\">" + ssCount + "</td>\r\n");
}
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Motor Vehicle Inventory</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Fleet Transactions</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Dealer Sales</td>\r\n");
end.append("      <td>&nbsp;</td>    \r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Subsequent Sales</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"7\" style=\"font-family: Arial; font-size: 8.25pt; padding: 10px 0px;\"><br>Sales amounts for the previous 12-month period corresponding to the prior tax year. If you were not in business for the entire 12-month period, report the sales for the months you were in business.</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
// PRC 195488 if the account has the imported months, the populated data will be from user's input, otherwise the populated data will be retrieved from database
if ( !importedMonths ) {
    end.append("      <td>" + nvl(amountMain, "$0.00") + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td>" + nvl(amountFL, "$0.00") + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td>" + nvl(amountDL, "$0.00") + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td>" + nvl(amountSS, "$0.00") + "</td>\r\n");
} else {
    end.append("      <td>" + formatMoney( invAmount )+ "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td>" + formatMoney( fsAmount ) + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td>" + formatMoney( dsAmount ) + "</td>\r\n");
    end.append("      <td>&nbsp;</td>\r\n");
    end.append("      <td>" + formatMoney( ssAmount ) + "</td>\r\n");
}
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Motor Vehicle Inventory</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Fleet Transactions</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Dealer Sales</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Subsequent Sales</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");
end.append("<img src=\"images/50-244-5.png\" width=\"778\" alt=\"STEP 5: Market Value of Motor Vehicle Inventory\" style=\"margin-top: 10px;\"/>\r\n");



end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">State the market value of the motor vehicle inventory for the current tax year, as computed under Tax Code Section 23.121. Market value is total annual sales less sales to dealers, fleet transactions, and subsequent sales, from the dealer's motor vehicle inventory for the previous 12-month period correspond- ing to the prior tax year divided by 12. Total annual sales is the total of the sales price from every sale from a dealer's motor vehicle inventory for a 12-month period. If you were not in business for the entire 12-month period, report the total number of sales for the months you were in business. The chief appraiser will determine the inventory's market value.</p>\r\n");

end.append("<table style=\"width: 500px; padding:0px; margin:0px;\">\r\n");
end.append("<tr>\r\n");
// PRC 195488 if the account has the imported months, the populated data will from user's input, otherwise the populated data will be retrieved from database
if ( !importedMonths ) {
    end.append("    <td>" + nvl(amountMain, "$0.00") + "</td>\r\n");
} else {
    end.append("    <td>" + formatMoney(priorTotal) + "</td>\r\n");
}
end.append("    <td>/ 12 =</td>\r\n");
end.append("    <td>\r\n");

if (isDefined(amountMain) && !importedMonths ){
    java.text.DecimalFormat df = new java.text.DecimalFormat("$###,###,###.00");
    end.append(df.format(Double.parseDouble(amountMain.replaceAll("[$,]", "") )/ 12.00));
} else if ( importedMonths ){
    end.append(formatMoney(market));
} else { 
    end.append("$0.00");
}

end.append("    </td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Dealer's Motor Vehicle Inventory Sales for Prior Year</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Market Value for Current Tax Year</td>\r\n");
end.append("</tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-244-6.png\" width=\"778\" alt=\"STEP 6: Signature and Date\" style=\"margin-top: 10px;\"/>\r\n");



end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">By signing this declaration, you certify that the dealer identified in Step 1 is the owner of a dealer's motor vehicle inventory.</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"3\">" + dNameline1 + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"3\" style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt; width: 550px;\">On Behalf of <em>(name of dealer)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td>" + uName + "</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td>" + uTitle + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt; width: 550px;\">Print Name</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Title</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Authorized Signature</td>\r\n");
end.append("      <td></td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Date</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<p style=\"font: bold 10px 'Arial';\">If you make a false statement on this report, you could be found guilty of a Class A misdemeanor or a state jail felony under Penal Code Section 37.10.</p>\r\n");
end.append("<div class=\"breakIt\"></div>\r\n");
end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" />\r\n");




end.append("<div style=\"text-align:center;font: 32px 'Times New Roman';color: #0061a2; margin: 20px 0px;\">Additional Instructions</div>\r\n");

end.append("<table id=\"addlInstructions\" style=\"width: 600px; padding:0px; margin:0px auto;text-align: justify;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td><strong>Step 4. Number of units sold and sale totals.</strong> The top row of boxes is the number of units sold for the preceding year in each category. The bottom row of boxes is the dollar amount sold for the previous year in each category. The categories include:\r\n");
end.append("      <ul>\r\n");
end.append("        <li><strong>Motor vehicle inventory </strong>-- sales of motor vehicles. A motor vehicle is a fully self-propelled vehicle with at least two wheels which has the primary purpose of transporting people or property (whether or not intended for use on a public street, road or highway) and includes a towable recreational vehicle. Motor vehicle does not include: 1. Vehicles with a certificate of title that has been surrendered in exchange for a salvage certificate; nor 2. equipment or machinery designed and intended for a specific work-related purpose other than transporting people or property. Motor vehicle inventory does not include fleet transactions, dealer sales or subsequent sales.<br><br></li>  \r\n");
end.append("        <li><strong>Fleet transaction</strong> -- motor vehicles included in the sale of five or more motor vehicles from your inventory to the same person within one calendar year.<br><br></li>\r\n");
end.append("        <li><strong>Dealer sales</strong> -- sales of vehicles to another Texas dealer or a dealer who is legally recognized in another state as a motor vehicle dealer.<br><br></li>\r\n");
end.append("        <li><strong>Subsequent sale</strong> -- dealer-financed sale of a motor vehicle that, at the time of sale, has been the subject of dealer financing from your motor vehicle inventory in the same calendar year.</li>\r\n");
end.append("      </ul>\r\n");
end.append("    </td>\r\n");
end.append("  </tr> \r\n");
end.append("</table>\r\n");

//end.append("<div class=\"breakIt\"></div>\r\n");
end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" style=\"margin: 20px 0px;\" />\r\n");

end.append("\r\n");
end.append("<div style=\"text-align:center;font-size: 24pt; font-family: 'Times New Roman';color: #0061a2; margin-bottom: 20px;\">Attachment</div>\r\n");
end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">Attach a list with the name and business address of each location at which you conduct business and each of the dealer's general distinguishing numbers issued by the Texas Department of Motor Vehicles.</p>\r\n");

end.append("  <table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");

if(ds.size() > 0){
    try{
        String[] businessNames      = new String[ ds.size() ];
        String[] locations          = new String[ ds.size() ];
        String[] addresses          = new String[ ds.size() ];
        String[] accountNumbers     = new String[ ds.size() ];
        String[] startDates         = new String[ ds.size() ];
        
        if ( isDefined( request.getParameter("formSubmitted") ) ){
            businessNames   = request.getParameterValues("businessName");
            locations       = request.getParameterValues("location");
            addresses       = request.getParameterValues("address");
            accountNumbers  = request.getParameterValues("accountNumber");
            startDates      = request.getParameterValues("startDate");
        }
        
        Dealership dealer = new Dealership();
       
        for (int i = 0 ; i < ds.size() ; i++){
            dealer = (Dealership) ds.get(i);
            // PRC 194344 Don't let the dealer information to be automatically populated
            end.append("<tr>\r\n");
            end.append("    <td style=\"height: 20px; vertical-align: bottom;\">");
            end.append( nvl(businessNames[i],"<input type=\"text\" name=\"businessName\" id=\"tpwd\" style=\"width: 510px;\" />") );
            end.append("    </td>\r\n" );
            end.append("    <td>&nbsp;</td>\r\n");
            end.append("    <td style=\"vertical-align: bottom;\">");
            end.append(     nvl( locations[i], "<input type=\"text\" name=\"location\" id=\"tpwd\" style=\"width: 250px;\" />") );
            end.append("    </td>\r\n" );
            end.append("</tr>\r\n");
            end.append("<tr>\r\n");
            end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt; width: 550px;\">Name of Business</td>\r\n");
            end.append("    <td>&nbsp;</td>\r\n");
            end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">General Distinguishing Number of Location</td>\r\n");
            end.append("</tr>\r\n");
            end.append("<tr>\r\n");
            end.append("    <td colspan=\"3\" style=\"height: 20px;vertical-align: bottom;\" >");
            end.append(     nvl( addresses[i],"<input type=\"text\" name=\"address\" id=\"tpwd\" style=\"width: 773px;\" />") );
            end.append("    </td>\r\n");
            end.append("</tr>\r\n");
            end.append("<tr>\r\n");
            end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Address, Street, City, State, ZIP Code</td>\r\n");
            end.append("</tr>    \r\n");
            end.append("<tr>\r\n");
            end.append("    <td style=\"height: 20px;vertical-align: bottom;\">");
            end.append(     nvl(accountNumbers[i],"<input type=\"text\" name=\"accountNumber\" id=\"tpwd\" style=\"width: 510px;\" />") );
            end.append("    </td>\r\n");
            end.append("    <td>&nbsp;</td>\r\n");
            end.append("    <td style=\"height: 20px;vertical-align: bottom;\">");
            end.append(     nvl(startDates[i],"<input type=\"text\" name=\"startDate\" id=\"tpwd\" style=\"width: 250px;\" />") );
            end.append("    </td>\r\n");
            end.append("</tr>\r\n");
            end.append("<tr>\r\n");
            end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt; width: 550px;\">Account Number <em>(if known)</em></td>\r\n");
            end.append("    <td>&nbsp;</td>\r\n");
            end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size: 6.75pt;\">Business Start Date, if Not in Business on Jan. 1</td>\r\n");
            end.append("</tr>\r\n");
            end.append("<tr><td colspan=\"3\">&nbsp;</td></tr>\r\n");

        }
    }catch (Exception e){ SITLog.error(e, "\r\nProblem in looping table for 50_244.jsp\r\n"); out.println( e.toString() ); }
} else {
    out.println("<tr><td colspan=\"3\" style=\"text-align: center;\">Sorry. No records found</td></tr>");
    end.append("<tr><td colspan=\"3\" style=\"text-align: center;\">Sorry. No records found</td></tr>");
}

end.append("</TABLE>\r\n");

end.append("<div id=\"version\" style=\"text-align: right; font-style: italic; font-size: 10px;\">50-244 * 04-15/12</div>\r\n");
end.append("</div><!--container -->\r\n");
end.append("</div><!--page holder -->\r\n");

if (notDefined(request.getParameter("formSubmitted"))){
    end.append("    </form>\r\n"); 
    end.append("    <script src=\"../assets/js/jquery.min.js\"></script> \r\n");
    end.append("    <script>\r\n");
    end.append("        $(document).ready(function() {\r\n");
    end.append("            $(\"#goBack\").on(\"click\", function(e){ \r\n");
    end.append("                e.preventDefault();\r\n");
    end.append("                e.stopPropagation(); \r\n");
    end.append("                var theForm = $(\"form#navigation\");\r\n");
    end.append("                theForm.prop(\"action\", \"../annualDeclaration.jsp\");\r\n");
    end.append("                theForm.submit();\r\n");
    end.append("            });\r\n");
    end.append("        });//doc ready\r\n");
    end.append("    </script>    \r\n");

}

 end.append("</BODY>\r\n");
 end.append("</HTML>\r\n");


if (isDefined(request.getParameter("formSubmitted"))){ 
  String thisPage = "50-244.jsp";
%>
 <%@ include file="_yearly.jsp"%>>
<%
}//if (isDefined(request.getParameter("formSubmitted)))


  try{
     out.print(start.toString() + middle.toString() + end.toString()); 
  } catch(Exception e){SITLog.error(e, "\r\nProblem writing StringBuffers for 50_244.jsp\r\n");}
%>