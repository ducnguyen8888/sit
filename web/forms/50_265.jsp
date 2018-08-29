<%@ include file="../_configuration.inc"
%><%--
    DN - 12/1/2017 - PRC 194344
        - Don't let the dealer information under attachment section to be automatically populated
    DN - 02/07/2018 - PRC 194604
        - Renamed "Finalize this Form" button to "Submit this Form to Tax Office"
        - Added the red banner behind submit button. It should say "Your form has not been submitted. Please click Submit this Form to the Tax Office"
        - Updated the confirmation notice
    DN - 2/12/2018 - PRC 195488
        - Only apply to Dallas County
        - If the account has the imported months, number of sold units, and sales amount will be the user's input instead of retrieving from database
    DN - 02/27/2018 - PRC 194604
        - Adjust the statement margin-top with red banner
        - Make sure that the top of statement is not pushed down when printing
    DN - 03/19/2018 - PRC 195488
        - Added hidden fields for users'input   
    DN - 05/30/2018 - PRC 194602
        - For 2017, the "Date Business Opened" or "Business Start Date" will be value in  "Start_Date" colum(taxdtl table).
        - If this value is null in table, the "Date Business Opened" or "Business Start Date" will be set by default "1/1"+ selected year
        - From 2018, the "Date Business Opened" or "Business Start Date" will be left blank
    DN - 06/06/2018 - PRC 194602
        Form wil be submitted without filling the fields
    DN - 06/15/2018 - PRC 194602
        In case the start date in taxdtl table is null, the start date field will be left blank instead of  populating a made up start date
    DN - 08/06/2018 - PRC 198588
        Updated the logic, declarationYear = declarationYear +1 if "ANNUAL_DECLARATION_YEAR" sit pref value = 1
--%><%! 
public StringBuffer getDealerAddress(Dealership d){
    StringBuffer sb = new StringBuffer();
    if (isDefined(d.nameline2)){ sb.append(d.nameline2); }
    if (isDefined(d.nameline3)){ sb.append(", " + d.nameline3); }
    if (isDefined(d.nameline4)){ sb.append(", " + d.nameline4); }
    sb.append(", " + nvl(d.city) + ", " + nvl(d.state) + " " + formatZip(d.zipcode));
    //if (isDefined(d.phone)){sb.append("<br>Phone: " + formatPhone(d.phone));}
    return sb;
}
public class BusinessInfo{
    public BusinessInfo( String businessName,
                        String numberofLocation,
                        String address ) {
        this.businessName       = businessName;
        this.numberofLocation   = numberofLocation;
        this.address            = address;

    }
    public String businessName      = "";
    public String numberofLocation  = "";
    public String address           = "";
}
%><script>
	// PRC 194604
    // Make sure that the top of statement is not pushed down when printing
    function Print(){
        window.onbeforeprint = function(){
            document.getElementById("container").style.marginTop = "-70px";
        }
        
        window.onafterprint = function(){
            document.getElementById("container").style.marginTop = "40px";
        }
      window.print();
    }
</script><%
StringBuffer start = new StringBuffer();
StringBuffer middle = new StringBuffer();
StringBuffer end = new StringBuffer();
String client_id = (String) session.getAttribute( "client_id");
String userid = (String) session.getAttribute( "userid");

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

String  invCount                = nvl(request.getParameter("invCount"),"0");
String  invAmount               = nvl(request.getParameter("invAmount"),"0");

String  rsCount                 = nvl(request.getParameter("rsCount"),"0");
String  rsAmount                = nvl(request.getParameter("rsAmount"),"0");

String  fsCount                 = nvl(request.getParameter("fsCount"),"0");
String  fsAmount                = nvl(request.getParameter("fsAmount"),"0");

String  dsCount                 = nvl(request.getParameter("dsCount"),"0");
String  dsAmount                = nvl(request.getParameter("dsAmount"),"0");

String  ssCount                 = nvl(request.getParameter("ssCount"),"0");
String  ssAmount                = nvl(request.getParameter("ssAmount"),"0");

String priorTotal               = nvl(request.getParameter("priorTotal"),"0");
String market                   = nvl(request.getParameter("market"),"0");


String startDate                = "";
int    declarationYear          = nvl( year, 0 );

StringBuffer sb = new StringBuffer();
sb.append("client_id  is " + client_id + "<br>");
sb.append("userid is " + userid + "<br>");
sb.append("can param is " + request.getParameter("can") + "<br>");
sb.append("can variab is " + request.getParameter("can") + "<br>");
if(request.getParameter("can") != null){

    PreparedStatement ps = null;
    ResultSet rs = null;
    Connection connection = null;

    connection = connect();
    
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
                SITLog.error(e, "\r\nProblem getting dealer in 50-265.jsp.\r\n");
            } finally {
               try { rs.close(); } catch (Exception e) { }
               rs = null;
               try { ps.close(); } catch (Exception e) { }
               ps = null;
            }// try get dealerships

            try { // Step #1 get the dealer info          
            StringBuffer sqlStr = new StringBuffer();
            sqlStr.append("select count(can), to_char(sum(sales_price), '$999,999,999.00') amount, sale_type");
            sqlStr.append(" from   sit_sales ");
            sqlStr.append(" where  can=? and year=? and status <> 'D' ");
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
                ps.setInt(2, 2017 );
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
                SITLog.error(e, "\r\nProblem getting totals for 50_265.jsp\r\n");
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
start.append("<META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\r\n");
start.append("<TITLE>Form 50-265</TITLE>\r\n");
start.append("<STYLE type=\"text/css\">\r\n");
start.append("  body {margin-top: 0px;margin-left: 0px;font-family: 'Arial'; font-size: 9pt;}\r\n");
start.append("  .page-holder { text-align: center; margin-top: 100px; }\r\n");
start.append("  button { width: 220px; margin: 0px 10px 10px 10px; }");
start.append("  #container { width: 778px; margin: 40px auto;font-family: 'Arial'; font-size: 9pt; text-align: left;}\r\n");
start.append("  #topImage { width: 778px; height: 120px; background-image: url(\"images/header.jpg\");}\r\n");
start.append("  #info1 p { margin-top: 5px; font: 10px 'Arial'; line-height: 12px;}\r\n");
start.append("  #finalizeNotice {padding-top: 10px; padding-bottom: 10px;}");
start.append("  .finalForm { text-align: center; background: red;  color: white; font-size: 14px; font-weight: bold; }\r\n");
start.append("  .tg  {border-collapse:collapse;border-spacing:0;}\r\n");
start.append("  .tg td{font-family:Arial, sans-serif;font-size:12px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("  .tg th{font-family:Arial, sans-serif;font-size:12px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}\r\n");
start.append("  .tg .tg-k2ip{font-weight:bold;font-size:10px;font-family:Arial, Helvetica, sans-serif !important;background-color:#e4ebf6;text-align:center;vertical-align:bottom;}\r\n");
start.append("  .tg .tg-yw4l{vertical-align:top}\r\n");
start.append("  .breakIt { page-break-after: always; }\r\n");
start.append("  #addlInstructions td {font-size: 9pt; font-family: Arial;}\r\n");
start.append("  #att { padding-left: 3px; letter-spacing: 2px; text-transform: uppercase; background: #FEFEAE; border-width: 1px; }\r\n");
start.append("     @media print {\r\n");
start.append("     #att { border: none; background: none; padding-left: 0px; }\r\n");
start.append("     .noprint{ display: none; }\r\n");
start.append("     }\r\n");
start.append("  </STYLE>\r\n");
start.append("</HEAD>\r\n");
start.append("<BODY>\r\n");

if (notDefined(request.getParameter("formSubmitted"))){
  middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
  middle.append("<div id=\"finalForm\" class=\"finalForm\">\r\n");
  // PRC 194604 add red banner and text
  middle.append("  <div id=\"finalizeNotice\">Your form has not been submitted. Please click Submit this Form to the Tax Office</div>\r\n");
  middle.append("  <form id=\"navigation\" action=\"\" method=\"post\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"declarationYear\" id=\"declarationYear\" value=\"" + declarationYear+ "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
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
  
  middle.append("    <input type=\"hidden\" name=\"formSubmitted\" id=\"formSubmitted\" value=\"yes\">\r\n");
  middle.append("    <button type=\"submit\" id=\"finalizeIt\" name=\"finalizeIt\">Submit this Form to the Tax Office</button>\r\n");
  middle.append("    <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
  //middle.append("  </form>\r\n");
  middle.append("</div>\r\n");
  middle.append("</div>\r\n");
}else {
  middle.append("<div style=\"position: fixed; top:0; left: 0; right: 0;\">\r\n");
  middle.append("<div style=\"text-align: center; background: red;  color: white; ");
  middle.append("padding-top: 10px; font-size: 14px; font-weight: bold; height: 80px;\" class=\"noprint\">");
  //PRC 194604 updated the confirmation notice
  middle.append("Your form has been submitted.<br>Please print a copy to keep for your records and a copy to mail to the Appraisal District.\r\n");
  middle.append("  <form id=\"navigation\" action=\"../annualDeclaration.jsp\" method=\"post\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
  middle.append("      <br>\r\n");
  middle.append("    <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
  middle.append("      <button type=\"button\" id=\"print\" name=\"print\" onclick =\"Print()\">Print</button>\r\n");

  middle.append("  </form>\r\n<br>");
  middle.append("</div>\r\n");
  middle.append("</div>\r\n");
}

end.append("<div class= \"page-holder\">\r\n");
end.append("<div id=\"container\">\r\n");

end.append("<img src=\"images/50-265.png\" alt=\"Inventory Declaration\" width=\"778\" />\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 150px;\">" + declarationYear + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Year</td>\r\n");
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
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">" + nvl(countyName) + " " + nvl(countyAddress1) + " " + nvl(countyAddress2) + "</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 150px;\">" + formatPhone(countyNumber) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Send Original to: County Tax Office Name and Address</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Phone (area code and number)</td>\r\n");
end.append("  </tr>  \r\n");
end.append("</table>\r\n");

end.append("<div id=\"info1\" style=\"margin: 10px 0px;\">\r\n");
end.append("<p><strong>GENERAL INSTRUCTIONS:</strong> This declaration is for a dealer of heavy equipment to declare heavy equipment inventory pursuant to Tax Code Section 23.1241. File a declaration for each business location.</p>\r\n");
end.append("<p><strong>WHERE TO FILE:</strong> Each declaration must be filed with the county appraisal district's chief appraiser and a copy of each declaration must be filed with the collector.</p>\r\n");
end.append("<p><strong>DECLARATION DEADLINES:</strong> Except as provided by Tax Code Section 23.1242(k), a declaration must be filed not later than February 1 of each year or, in the case of a dealer who was not in business on January 1, not later than 30 days after commencement of the business.</p>\r\n");
end.append("<p><strong>PENALTIES:</strong> In addition to other penalties provided by law, a dealer who fails to file or timely file a required declaration must forfeit a penalty of $1,000 for each month or part of a month in which a declaration is not filed or timely filed after it is due. A tax lien attaches to the dealer's business personal property to secure payment of the penalty.</p>\r\n");
end.append("<p style=\"text-align: center;\"><strong>OTHER IMPORTANT INFORMATION:</strong></p>\r\n");
end.append("<p>The chief appraiser may examine the books and records of a dealer, including documentation regarding the applicability of Tax Code Section 23.1241 and Tax\r\n");
end.append("Code Section 23.1242 and sales records to substantiate information set forth in filed declarations.</p>\r\n");
end.append("</div>\r\n");
end.append("<img src=\"images/50-265-1.png\" width=\"778\" style=\"margin-bottom: 10px;\" alt=\"Section 1\" />\r\n");


end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + dNameline1 + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Name of Dealer for Which Inventory is Being Declared</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
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
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Current Mailing Address <em>(number and street)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uCity + ", " + uState + " " + formatZip(uZipcode) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">City, State, ZIP Code</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">&nbsp;</td>\r\n");
end.append("    <td style=\"width: 30px;\">&nbsp;</td>\r\n");
end.append("    <td style=\"width: 140px;\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  </table>\r\n");

end.append("<img src=\"images/50-265-2.png\" width=\"778\" style=\"margin-bottom: 10px;\" alt=\"Section 2\" />\r\n");


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
end.append("        <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\" colspan=\"3\">Address of Location <em>number, street, city, state, ZIP code</em></td>\r\n");
end.append("    </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-265-3.png\" width=\"778\" style=\"margin: 10px 0px;\" alt=\"Section 3\" />\r\n");

end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">You must attach a list with the name and business address of each location at which you conduct business.</p>\r\n");
end.append("<div class=\"breakIt\"></div>\r\n");
end.append("<img src=\"images/50-265-4.png\" width=\"778\" style=\"margin-bottom: 10px;\" alt=\"Section 4\" />\r\n");


end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("      <td>" + aprdistacc + "</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
//PRC 194602 - 05/30/2018 Modified the logic how the value is set in  the "Date Business Opened" or "Business Start Date" field
if ("2017".equals( year) ) {
    end.append("        <td>" + startDate + "</td>\r\n");
} else {
    end.append("        <td>&nbsp;</td>\r\n");
}
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial'; width: 400px;\">Account Number</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Starting Date of Business, if Not in Business on January 1st of This Year</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-265-5.png\" width=\"778\" style=\"margin-top: 10px;\" alt=\"Section 5\" />\r\n");

end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">Complete the boxes on the number of units sold, leased or rented and the transaction amounts for the preceding year. See last page for definitions.</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"7\" style=\"font: 11px 'Arial';\"><strong>Part I. Number of Units of Heavy Equipment:</strong> Breakdown of sales, rentals, and leases for the previous 12-month period corresponding to the prior tax year. Provide the number of units for the business location for which you are declaring inventory (identified in SECTION 2). If you were not in business for the entire 12-month period, report the sales, leases, and rentals for the months you were in business.</td>\r\n");
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
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Net Heavy Equipment Inventory</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Fleet Transactions</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Dealer Sales</td>\r\n");
end.append("      <td>&nbsp;</td>    \r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Subsequent Sales</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"7\" style=\"font: 11px 'Arial';\"><br><strong>Part II. Transaction Amount:</strong> Breakdown of sales, leases, and rentals amounts for the previous 12-month period corresponding to the prior tax year. Provide the transaction amounts for the business location for which you are declaring inventory (identified in SECTION 2). If you were not in business for the entire 12-month period, report the sales, leases, and rentals for the months you were in business.</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
// PRC 195488 if the account has the imported months, the populated data will be from user's input, otherwise the populated data will be retrieved from database
if ( !importedMonths ){
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
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Net Heavy Equipment Inventory</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Fleet Transactions</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Dealer Sales</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Subsequent Sales</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-265-6.png\" width=\"778\" style=\"margin-top: 10px;\" alt=\"Section 6\" />\r\n");

end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">State the market value of your net heavy equipment inventory for the current tax year, as computed under Tax Code Section 23.1241. Market value on January 1 is total annual sales (less fleet transactions, dealer sales, and subsequent sales) for the previous 12-month period corresponding to the prior tax year divided by 12. If you were not in business for the entire 12-month period, report the number of months you were in business and the total number of sales for those months; the chief appraiser will estimate your inventory's market value.<br><br>\r\n");
end.append("Total annual sales includes the sales price for each sale of heavy equipment inventory in a 12-month period PLUS lease and rental payment(s) received for each lease or rental in that 12-month period. This will be the same amount as the net heavy equipment inventory transaction amount (see Section 5, the first box in Part II) and divide by 12 to yield your market value for this tax year. If you were not in business for the entire preceding year, the chief appraiser will estimate your inventory's market value.</p>\r\n");

end.append("<table style=\"width: 500px; padding:0px; margin:0px;\">\r\n");
end.append("<tr>\r\n");
// PRC 195488 if the account has the imported months, the populated data will be from user's input, otherwise the populated data will be retrieved from database
if ( !importedMonths ) {
    end.append("    <td>" + nvl(amountMain, "$0.00") + "</td>\r\n");
} else {
    end.append("    <td>" + formatMoney(priorTotal) + "</td>\r\n");
}
end.append("    <td style=\"text-align: center;\">/ 12 =</td>\r\n");
end.append("    <td>\r\n");
// PRC 195488 if the account has the imported months, the populated data will be from user's input, otherwise the populated data will be retrieved from database     
if (isDefined(amountMain) && !importedMonths ){
  java.text.DecimalFormat df = new java.text.DecimalFormat("$###,###,###.00");
  end.append(df.format(Double.parseDouble(amountMain.replaceAll("[$,]", "") )/ 12.00));
} else if ( importedMonths ) { 
    end.append(formatMoney(market));
} else {
    end.append("$0.00");
}
       
end.append("    </td>\r\n");
end.append("</tr>\r\n");
end.append("<tr>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';width: 220px;\">Net Heavy Equipment Inventory Sales, Leases,<br>and Rentals for Prior Year</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';width: 220px; vertical-align: top;\">Market Value for Current Tax Year</td>\r\n");
end.append("</tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-265-7.png\" width=\"778\" style=\"margin-top: 10px;\" alt=\"Section 7\" />\r\n");

end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">By signing this declaration, you certify that the dealer identified in Step 1 is the owner of a dealer's motor vehicle inventory.</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"3\">" + dNameline1 + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"3\" style=\"border-top: 1px solid #6594c5; font: 9px 'Arial'; width: 550px;\">On Behalf of <em>(name of dealer)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("    <tr>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Authorized Signature</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Date</td>\r\n");
end.append("  </tr>\r\n");
end.append("    <tr>\r\n");
end.append("      <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td>" + uName + "</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td>" + uTitle + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial'; width: 550px;\">Print Name</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font: 9px 'Arial';\">Title</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<p style=\"font: bold 10px 'Arial';\">If you make a false statement on this form, you could be found guilty of a Class A misdemeanor or a state jail felony under Section 37.10, Penal Code.</p>\r\n");
end.append("<div class=\"breakIt\"></div>\r\n");
end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" />\r\n");

end.append("<div style=\"text-align:center;font: 32px 'Times New Roman';color: #0061a2; margin: 20px 0px;\">Definitions</div>\r\n");

end.append("<table id=\"addlInstructions\" style=\"width: 600px; padding:0px; margin:0px auto;text-align: justify;style=\"overflow: wrap\"\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style='font-size: 8pt;'>\r\n");
end.append("    <strong>Net Heavy Equipment Inventory</strong> - Heavy equipment units that have been sold, leased, or rented less fleet transactions, dealer sales and subsequent sales. Heavy equipment means self-propelled, self-powered or pull-type equipment, including farm equipment or a diesel engine, which weighs at least 1,500 pounds and is intended to be used for agricultural, construction, industrial, maritime, mining or forestry uses. The term does not include a motor vehicle that is required to be titled under Transportation Code Chapter 501 or registered under Transportation Code Chapter 502.\r\n");
end.append("      <p><strong>Fleet Transactions</strong> - The sale of five or more items of heavy equipment from your inventory to the same buyer within one calendar year.</p>\r\n");
end.append("      <p><strong>Dealer Sales</strong> - Sales to dealers.</p>\r\n");
end.append("      <p><strong>Subsequent Sales</strong> - A dealer-financed sale and that, at the time of sale, has dealer financing from your inventory in this same calendar year. The term does not include a rental or lease with an unexercised purchase option or without a purchase option.</p>\r\n");
end.append("    </td>\r\n");
end.append("  </tr> \r\n");
end.append("</table>\r\n");

//end.append("<div class=\"breakIt\"></div>\r\n");

end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" style=\"margin-top: 20px;\" />\r\n");

end.append("<div style=\"text-align:center;font: 32px 'Times New Roman';color: #0061a2; margin: 20px 0px;\">Attachment</div>\r\n");
end.append("<p style=\"font: 11px 'Arial';margin-top:0px;\">You must attach a list with the name and business address of each location at which you conduct business.</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");

// loop, loop, loop
if(ds.size() > 0){
    try{
        
        String[] businessNames      = new String[ ds.size() ];
        String[] locations          = new String[ ds.size() ];
        String[] addresses          = new String[ ds.size() ];
        
        if ( isDefined( request.getParameter("formSubmitted") ) ){
            businessNames   = request.getParameterValues("businessName");
            locations       = request.getParameterValues("location");
            addresses       = request.getParameterValues("address");
        }
        
        Dealership dealer = new Dealership();
    
        for (int i = 0 ; i < ds.size() ; i++){
            dealer = (Dealership) ds.get(i);
            // PRC 194344 Don't let the dealer information to be automatically populated
            end.append("<tr>\r\n");
            end.append("    <td style=\"height: 20px; vertical-align: bottom;\">");
            end.append(     nvl(businessNames[i],"<input type=\"text\" name=\"businessName\" id=\"att\" style=\"width: 510px;\" />") );
            end.append("    </td>\r\n");
            end.append("    <td>&nbsp;</td>\r\n");
            end.append("    <td style=\"vertical-align: bottom;\">");
            end.append(     nvl(locations[i],"<input type=\"text\" name=\"location\" id=\"att\" style=\"width: 250px;\" />") );
            end.append("    </td>\r\n");
            end.append("</tr>\r\n");
            end.append("<tr>\r\n");
            end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial'; width: 550px;\">Name of Business</td>\r\n");
            end.append("    <td>&nbsp;</td>\r\n");
            end.append("    <td style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">General Distinguishing Number of Location</td>\r\n");
            end.append("</tr>\r\n");
            end.append("<tr>\r\n");
            end.append("    <td colspan=\"3\" style=\"height: 20px;vertical-align: bottom;\" >");
            end.append(     nvl(addresses[i], "<input type=\"text\" name=\"address\" id=\"att\" style=\"width: 773px;\" />") );
            end.append("    </td>\r\n");
            end.append("</tr>\r\n");
            end.append("<tr>\r\n");
            end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font: 9px 'Arial';\">Address, Street, City, State, ZIP Code</td>\r\n");
            end.append("</tr>    \r\n");
            end.append("<tr><td colspan=\"3\">&nbsp;</td></tr>\r\n");

        }
    }catch (Exception e){
        SITLog.error(e, "\r\nProblem in the table loop for 50_265.jsp\r\n");
    }
} else {
    end.append("<tr><td colspan=\"3\" style=\"text-align: center;\">Sorry. No records found</td></tr>");
}

 end.append("</TABLE>\r\n"); 

end.append("<div id=\"version\" style=\"text-align: right; font-style: italic; font-size: 10px;\">50-265 * 02-12/5</div>\r\n");
end.append("</div><!--container -->\r\n");
end.append("</div><!--page holder -->\r\n");

if (notDefined(request.getParameter("formSubmitted"))){
    end.append("    </form>\r\n"); 
    end.append("    </form>\r\n"); 
    end.append("<script src=\"../assets/js/jquery.min.js\"></script> \r\n");
    end.append("<script>\r\n");
    end.append("    $(document).ready(function() {\r\n");
    end.append("        $(\"#goBack\").on(\"click\", function(e){ \r\n");
    end.append("            e.preventDefault();\r\n");
    end.append("            e.stopPropagation(); \r\n");
    end.append("            var theForm = $(\"form#navigation\");\r\n");
    end.append("            theForm.prop(\"action\", \"../annualDeclaration.jsp\");\r\n");
    end.append("            theForm.submit();\r\n");
    end.append("        });\r\n");
    end.append("    });//doc ready\r\n");
    end.append("</script>    \r\n");
} 

end.append("</BODY>\r\n");
end.append("</HTML>\r\n");



if (isDefined(request.getParameter("formSubmitted"))){ 
  String thisPage = "50-265.jsp";
%>
  <%@ include file="_yearly.jsp"%>
<%
}//if (isDefined(request.getParameter("formSubmitted"))){





    try{
     out.print(start.toString() + middle.toString() + end.toString()); 
    } catch(Exception e){SITLog.error(e, "\r\nProblem writing StringBuffers for 50_265.jsp\r\n");} 
%>
