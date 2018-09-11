<%@ include file="../_configuration.inc"
%><%--
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
        - Form wil be submitted without filling the fields
    DN - 06/15/2018 - PRC 194602
        - In case the start date in taxdtl table is null, the start date field will be left blank instead of  populating a made up start date
    DN - 08/06/2018 - PRC 198588
        - Populated can in the 'TPWD' field
        - Removed the attachment section
        - Updated the logic, declarationYear = declarationYear +1 if "ANNUAL_DECLARATION_YEAR" sit pref value = 1
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

public boolean isArrayNotNull(String [] array) {
    boolean arrayIsNotNull = false;
    for ( int i= 0; i < array.length; i++){
        if ( isDefined( array[i]) ) {
            arrayIsNotNull = true;
        }
    }
    
    return arrayIsNotNull;
}

%><script>
	// PRC 194604
    // Make sure that the top of statement is not pushed down when printing
   function Print(){ 
        window.onbeforeprint = function(){
            $("#container").css("margin-top","-70px");
        }
        
        window.onafterprint = function(){
             $("#container").css("margin-top","60px");
        }
         window.print();
    }
	
</script><%
StringBuffer start              = new StringBuffer();
StringBuffer middle             = new StringBuffer();
StringBuffer end                = new StringBuffer();
String client_id                = (String) session.getAttribute( "client_id");
String userid                   = (String) session.getAttribute( "userid");

String dNameline1               = "";
String dNameline2               = "";
String dNameline3               = "";
String dNameline4               = "";
String dCity                    = "";
String dState                   = "";
String dCountry                 = "";
String dZipcode                 = "";
String dPhone                   = "";
StringBuffer dAddress           = new StringBuffer();

String uName                    = "";
String uTitle                   = "";
String uAddress1                = "";
String uAddress2                = "";
String uCity                    = "";
String uState                   = "";
String uZipcode                 = "";
String uPhone                   = "";
StringBuffer uAddress           = new StringBuffer();

String countDL                  = "";
String countFL                  = "";
String countMain                = "";
String countSS                  = "";
String countRL                  = "";
String amountDL                 = "";
String amountFL                 = "";
String amountMain               = "";
String amountSS                 = "";
String amountRL                 = "";

String appraisalName            = "";
String appraisalNumber          = "";
String countyName               = "";
String countyAddress1           = "";
String countyAddress2           = "";
String countyNumber             = "";
String todaysDate               = "";
String aprdistacc               = "";//named like the db field

String startDate                = "";
int    declarationYear          = nvl( year, 0 );

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
    startDate   = getStartDate(connection, ps, rs, client_id, can , year );
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
                    dNameline1      = nvl(rs.getString(1));
                    dNameline2      = nvl(rs.getString(2));
                    dNameline3      = nvl(rs.getString(3));
                    dNameline4      = nvl(rs.getString(4));
                    dCity           = nvl(rs.getString(5));
                    dState          = nvl(rs.getString(6));
                    dCountry        = nvl(rs.getString(7));
                    dZipcode        = nvl(rs.getString(8));
                    dPhone          = nvl(rs.getString(9));
                    if (isDefined(dNameline2)) dAddress.append(dNameline2 + " ");
                    if (isDefined(dNameline3)) dAddress.append(dNameline3 + " ");
                    if (isDefined(dNameline4)) dAddress.append(dNameline4 + " ");
                    uName           = nvl(rs.getString(10));
                    uTitle          = nvl(rs.getString(11));
                    uAddress1       = nvl(rs.getString(12));
                    uAddress2       = nvl(rs.getString(13));
                    uCity           = nvl(rs.getString(14));
                    uState          = nvl(rs.getString(15));
                    uZipcode        = nvl(rs.getString(16));
                    uPhone          = nvl(rs.getString(17));
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
                SITLog.error(e, "\r\nProblem getting dealers for 50_259.jsp\r\n");
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
            sqlStr.append(" where  can = ? and year=? and status <> 'D' ");
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
                SITLog.error(e, "\r\nProblem getting totals for 50_259.jsp\r\n");
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
start.append("  <HEAD>\r\n");
start.append("  <META http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\r\n");
start.append("  <TITLE>Form 50-259</TITLE>\r\n");
start.append("  <STYLE type=\"text/css\">\r\n");
start.append("    body {margin-top: 0px;margin-left: 0px;}\r\n");
start.append("    .page-holder { text-align: center; margin-top: 100px; }\r\n");
start.append("    button { width: 220px; margin: 0px 10px 10px 10px; }");
start.append("    #container { width: 778px; margin: 60px auto; font-family: Arial; font-size: 9pt; text-align: left;}\r\n");
start.append("    #topImage { width: 778px; height: 120px; background-image: url(\"images/header.jpg\");}\r\n");
start.append("    #info1 p { margin-top: 5px; font-size: 7.5pt; font-family: Arial; line-height: 12px;}\r\n");
start.append("    #licenseInfo { text-align: center; background: red; height: 40px; color: white; padding-top: 20px; margin-bottom: 10px; font-size: 14px; font-weight: bold; }\r\n");
start.append("	  #finalizeNotice {padding-top: 10px; padding-bottom: 10px;}");
start.append("    .finalForm { text-align: center; background: red;  color: white; font-size: 14px; font-weight: bold; }\r\n");
start.append("    .tg  {border-collapse:collapse; border-spacing:0;}\r\n");
start.append("    .tg td{font-family:Arial; font-size:9pt; padding:10px 5px; border-style:solid; border-width:1px; overflow:hidden; word-break:normal;}\r\n");
start.append("    .tg th{font-family:Arial; font-size:9pt; font-weight:normal; padding:10px 5px; border-style:solid; border-width:1px; overflow:hidden; word-break:normal;}\r\n");
start.append("    .tg .tg-k2ip{font-weight:bold; font-size:10px; font-family:Arial, Helvetica, sans-serif !important; background-color:#e4ebf6; text-align:center; vertical-align:bottom;}\r\n");
start.append("    .tg .tg-yw4l{vertical-align:top}\r\n");
start.append("    .breakIt { page-break-after: always; }\r\n");
start.append("    #addlInstructions td {font-family: Arial; font-size: 9pt;}\r\n");
start.append("    .license { padding-left: 3px; letter-spacing: 2px; text-transform: uppercase; background: #FEFEAE; border-width: 1px; }\r\n");
start.append("    @media print {\r\n");
start.append("       .license { border: none; background: none; padding-left: 0px; }\r\n");
start.append("       .noprint{ display: none; }\r\n");
start.append("    }\r\n");
start.append("  </STYLE>\r\n");
start.append("</HEAD>\r\n");
start.append("<BODY>\r\n");
// PRC 190387  let Dallas finalize the forms(50_259 and 50_267) without filling license #
if ( notDefined( request.getParameter("formSubmitted") ) ){
  middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
  middle.append("<div id=\"finalForm\" class=\"finalForm\">\r\n");
  // PRC 194604 add red banner and text
  middle.append("    <div id=\"finalizeNotice\">Your form has not been submitted. Please click Submit this Form to the Tax Office</div>\r\n");
  middle.append("    <form id=\"navigation\" action=\"\" method=\"post\">\r\n");
  middle.append("        <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
  middle.append("        <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
  middle.append("        <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
  middle.append("        <input type=\"hidden\" name=\"declarationYear\" id=\"declarationYear\" value=\"" + declarationYear+ "\">\r\n");
  middle.append("        <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
  middle.append("        <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
  middle.append("        <input type=\"hidden\"  name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
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
  middle.append("        <input type=\"hidden\" name=\"formSubmitted\" id=\"formSubmitted\" value=\"yes\">\r\n");
  // PRC 194604 rename button
  middle.append("        <button type=\"submit\" id=\"finalizeIt\" name=\"finalizeIt\">Submit this Form to the Tax Office</button>\r\n");
  middle.append("        <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
//  middle.append("    </form>\r\n");
  middle.append("  </div>\r\n");
  middle.append("</div>\r\n");
} else {
  middle.append("<div style=\"position: fixed; top: 0; left: 0; right: 0;\">\r\n");
  middle.append("<div style=\"text-align: center; background: red;  color: white; ");
  middle.append("padding-top: 10px; font-family: Arial; font-size: 14px; font-weight: bold; height: 80px;\" class=\"noprint\">");
  //PRC 194604 updated the confirmation notice
  middle.append("Your form has been submitted.<br>Please print a copy to keep for your records and a copy to mail to the Appraisal District.\r\n");
  middle.append("  <form id=\"navigation\" action=\"../annualDeclaration.jsp\" method=\"post\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"can\" id=\"can\" value=\"" + request.getParameter("can") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"name\" id=\"name\" value=\"" + request.getParameter("name") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"year\" id=\"year\" value=\"" + request.getParameter("year") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"month\" id=\"month\" value=\"" + request.getParameter("month") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"category\" id=\"category\" value=\"" + request.getParameter("category") + "\">\r\n");
  middle.append("    <input type=\"hidden\" name=\"bizStart\" id=\"bizStart\" value=\"" + request.getParameter("bizStart") + "\">\r\n");
  middle.append("    <br>\r\n");
  middle.append("    <button type=\"submit\" id=\"goBack\" name=\"goBack\">Go Back</button>\r\n");
  middle.append("    <button type=\"button\" id=\"print\" name=\"print\" onclick =\"Print()\">Print</button>\r\n");
  middle.append("  </form>\r\n<br>");
  middle.append("</div>\r\n");
  middle.append("</div>\r\n");
}

end.append("<div class= \"page-holder\">\r\n");
end.append("<div id=\"container\">\r\n");

end.append("<img src=\"images/50-259.png\" width=\"778\" alt=\"Inventory Declaration\" />\r\n");


end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td style=\"width: 600px;\">&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"width: 150px;\">" + declarationYear + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Year</td>\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Send Original to: County Tax Office Name and Address</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Phone <em>(area code and number)</em></td>\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Send Copy to: Appraisal District Name and Address</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Phone <em>(area code and number)</em></td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");


end.append("<div id=\"info1\" style=\"margin: 10px 0px;\">\r\n");
end.append("<p style=\"font-family: Arial; font-weight: bold; font-size: 7.5pt; margin-bottom: 5px;\">This document must be filed with the appraisal district office and the county tax assessor-collector's office in the county in which your business is located. Do not file this document with the office of the Texas Comptroller of Public Accounts. Location and address information for the appraisal district office in your county may be found at comptroller.texas.gov/propertytax/references/directory/cad. Location and address information for the county tax assessor-collector's office in your county may be found at comptroller.texas.gov/propertytax/references/directory/tac.</p>\r\n");
end.append("<img src=\"images/lite-blue.png\" width=\"778\" height=\"6\" />\r\n");



end.append("<p><strong>GENERAL INSTRUCTIONS:</strong> This declaration is for a dealer of vessels and outboard motors to declare vessel and outboard motor inventory pursuant to\r\n");
end.append("Tax Code Section 23.124. File a declaration for each business location.</p>\r\n");
end.append("<p><strong>WHERE TO FILE:</strong> This declaration, and all supporting documentation, must be filed with the appraisal district office in the county in which your business is located. A copy of each declaration must be filed with the county tax assessor-collector's office.</p>\r\n");
end.append("<p><strong>DECLARATION DEADLINES:</strong> Except as provided by Tax Code Section 23.125(l), a declaration must be filed not later than Feb. 1 of each year or, in the case of a dealer who was not in business on Jan. 1, not later than 30 days after commencement of the business.</p>\r\n");
end.append("<p><strong>PENALTIES:</strong> A dealer who fails to file a declaration commits a misdemeanor offense punishable by a fine not to exceed $500. Each day during which a dealer fails to comply is a separate violation. In addition to other penalties provided by law, a dealer who fails to file or timely file a required declaration must forfeit a penalty of $1,000 for each month or part of a month in which a declaration is not filed or timely filed after it is due. A tax lien attaches to the dealer's business personal property to secure payment of the penalty.</p>\r\n");
end.append("<p style=\"text-align: center;\"><strong>OTHER IMPORTANT INFORMATION:</strong></p>\r\n");
end.append("<p>The chief appraiser and collector may examine the books and records of a dealer as provided by Tax Code Section 23.124(g) and 23.125(f).</p>\r\n");
end.append("</div>\r\n");
end.append("<img src=\"images/50-259-1.png\" width=\"778\" alt=\"STEP 1: Dealer Information\" style=\"margin: 10px 0px;\" />\r\n");



end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uName + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Name of Dealer</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\">" + uAddress1 + nvl(uAddress2) + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("    <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Mailing Address</td>\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">City, State, ZIP Code</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Phone <em>(area code and number)</em></td>\r\n");
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
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Name of Person Completing Statement</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Title</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-259-2.png\" alt=\"STEP 2: Business Information\" width=\"778\" style=\"margin: 10px 0px;\" />\r\n");


end.append("<p style=\"font-family:Arial;font-size:8.25pt;margin-top:0px;\">Attach a list with the name and business address of each location at which you conduct business and each of the dealer's and manufacturer's numbers issued by the Texas Parks and Wildlife Department (TPWD).</p>\r\n");
end.append("<div class=\"breakIt\"></div>\r\n");

end.append("<img src=\"images/50-259-3.png\" alt=\"STEP 3: Business Location of Declared Inventory\" width=\"778\" />\r\n");
end.append("<p style=\"font-family:Arial;font-size:8.25pt;margin-top:0px;\">Provide the business name, TPWD dealer's and manufacturer's numbers, and physical business address of the business location for the inventory you are declaring in this form. Provide the appraisal district account number if available or attach a tax bill or copy of appraisal or tax office correspondence concerning your account.</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("    <tr>\r\n");
end.append("        <td>" +  dNameline1 + "</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td>");
// PRC 198588 - 08/06/2018 - populate can in the "TPWD" field
end.append(nvl(request.getParameter("singleLicense"),
                  "<input type=\"text\" name=\"singleLicense\" class=\"license\" style=\"width: 300px;\" value='"+ can +"' />"));
end.append("</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Name of Business</td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">TPWD Dealer's and Manufacturer's Number</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">&nbsp;</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td colspan=\"3\">" + dAddress.toString() + ", " + dCity + ", " + dState + " " + dZipcode + "</td>\r\n");
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\" colspan=\"3\">Address, City, State, ZIP Code</td>\r\n");
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
end.append("    </tr>\r\n");
end.append("    <tr>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt; width: 550px;\">Appraisal District Account Number <em>(if known)</em></td>\r\n");
end.append("        <td>&nbsp;</td>\r\n");
end.append("        <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Business Start Date, if Not in Business on Jan. 1</td>\r\n");
end.append("    </tr>\r\n");
end.append("</table>\r\n");
 
end.append("<img src=\"images/50-259-4.png\" alt=\"STEP 4: Breakdown of Sales and Sales Amounts\" width=\"778\" style=\"margin: 10px 0px;\" />\r\n");



end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append(" <tr>\r\n");
end.append("      <td colspan=\"7\" style=\"font-family:Arial;font-weight:bold;font-size:8.25pt;\">Breakdown of units sold for the previous 12-month period corresponding to the prior tax year. If you were not in business for the entire 12-month period, report the units sold for the months you were in business. See last page for additional instructions.</td>\r\n");
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
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Vessel and Outboard Motor Inventory</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Fleet Transactions</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Dealer Sales</td>\r\n");
end.append("      <td>&nbsp;</td>    \r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Subsequent Sales</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td colspan=\"7\" style=\"font-family: Arial;font-weight: bold; font-size: 8.25pt;\"><br>Breakdown of sales amounts for the previous 12-month period corresponding to the prior tax year. If you were not in business for the entire 12-month period, report the sales amounts for the months you were in business.</td>\r\n");
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
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Vessel and Outboard Motor Inventory</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Fleet Transactions</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Dealer Sales</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Subsequent Sales</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-259-5.png\" alt=\"STEP 5: Market Value of Your Inventory\" width=\"778\" style=\"margin: 10px 0px;\" />\r\n");



end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">State the market value of the inventory for the current tax year as computed under Tax Code Section 23.124. Market value is total annual sales from the dealer's inventory less sales to dealers, fleet transactions, and subsequent sales for the previous 12-month period corresponding to the prior tax year divided by 12. Total annual sales is the total of the sales price from every sale from the inventory for a 12-month period. If you were not in business for the entire 12-month period, report the sales for those months you were in business and the chief appraiser will determine the inventory's market value.</p>\r\n");

end.append("<table style=\"width: 500px; padding:0px; margin:0px;\">\r\n");
end.append("<tr>\r\n");
// PRC 195488 if the account has the imported months, the populated data will be from user's input, otherwise the populated data will be retrieved from database
if ( !importedMonths ) {
    end.append("    <td>" + nvl(amountMain, "$0.00") + "</td>\r\n");
} else {
    end.append("    <td>" + formatMoney(priorTotal) + "</td>\r\n");
}
end.append("    <td>/ 12 =</td>\r\n");
end.append("    <td>\r\n");
// PRC 195488 if the account has the imported months, the populated data will from user's input, otherwise the populated data will be retrieved from database
if ( isDefined(amountMain) && !importedMonths ){
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
end.append("    <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Vessel and Outboard Motor Inventory Sales for Prior Year</td>\r\n");
end.append("    <td>&nbsp;</td>\r\n");
end.append("    <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Market Value for Current Tax Year</td>\r\n");
end.append("</tr>\r\n");
end.append("</table>\r\n");

end.append("<img src=\"images/50-259-6.png\" alt=\"STEP 6: Signature and Date\" width=\"778\" style=\"margin: 10px 0px;\" />\r\n");




end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">By signing this declaration, you certify that the dealer identified in Step 1 is the owner of a dealer's motor vehicle inventory.</p>\r\n");

end.append("<table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");
end.append("  <tr>\r\n");
end.append("      <td>" + uName + "</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td>" + uTitle + "</td>\r\n");
end.append("  </tr>\r\n");
end.append("  <tr>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt; width: 550px;\">Print Name</td>\r\n");
end.append("      <td>&nbsp;</td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Title</td>\r\n");
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
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Authorized Signature</td>\r\n");
end.append("      <td></td>\r\n");
end.append("      <td style=\"border-top: 1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Date</td>\r\n");
end.append("  </tr>\r\n");
end.append("</table>\r\n");

end.append("<p style=\"font-family: Arial; font-weight: bold; font-size: 7.5pt;\">If you make a false statement on this report, you could be found guilty of a Class A misdemeanor or a state jail felony under Penal Code Section 37.10.</p>\r\n");
end.append("<div class=\"breakIt\"></div>\r\n");
end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" />\r\n");



end.append("<div style=\"text-align:center;font-size: 24pt; font-family: 'Times New Roman';color: #0061a2; margin: 20px 0px;\">Additional Instructions</div>\r\n");

end.append("<table id=\"addlInstructions\" style=\"width: 600px; padding:0px; margin:0px auto;text-align: justify;\">\r\n");
end.append("  <tr>\r\n");
end.append("    <td><strong>Step 4: Breakdown of units and sales amounts.</strong> Complete the boxes on units sold and sales amounts for the preceding year. The top row of boxes is the number of units sold in each category. The bottom row of boxes is the dollar amount sold in each category. The categories include:\r\n");
end.append("      <ul>\r\n");
end.append("        <li><strong>Vessel and outboard motor inventory</strong> - the sale of watercraft used or capable of being used for transportation on water that are not more than 65 feet in length (vessels) and the sale of self-contained internal combustion propulsion systems which are used to propel vessels and which are detachable as a unit from the vessel (outboard motors). The term \"vessel\" also includes a vehicle that is designed to carry watercraft and is either a \"trailer\" or \"semitrailer\" as defined by Transportation Code Section 501.002(23) and (29). The term \"vessel\" does not include watercraft of more than 65 feet in length; or a seaplane on water; or canoes, kayaks, punts, rowboats, rubber rafts, or other vessels under 14 feet in length when paddled, poled, oared, or windblown. This category does not include a fleet transaction, dealer sale, or sub- sequent sale, each of which is defined below. [See, Tax Code Sections 23.124(a)(8), (14), (15); and Parks and Wildlife Code, Section 31.003.]<br><br></li>\r\n");
end.append("        <li><strong>Fleet transaction</strong> - the sale of five or more vessels or outboard motors from a dealer's vessel and outboard motor inventory to the same business entity within one calendar year. [Tax Code Section 23.124(a)(7).]<br><br></li>\r\n");
end.append("        <li><strong>Dealer sale</strong> - the sale from a dealer's vessel and outboard motor inventory to another dealer, that is, a person who holds a dealer's and manufacturer's number issued by the Parks and Wildlife Department under the authority of Parks and Wildlife Code Section 31.041, or is authorized by law or interstate reciprocity agreement to purchase vessels or outboards motors in Texas without paying the sales tax. The term does not include the manufacturer of vessels or outboard motors. [See, Tax Code Section 23.124(a)(3).]<br><br></li>\r\n");
end.append("        <li><strong>Subsequent sale</strong> - a dealer-financed sale of a vessel or outboard motor that, at the time of the sale, has been the subject of a dealer-financed sale from the same dealer's vessel and outboard motor inventory in the same calendar year. [Tax Code Section 23.124(a)(12).]</li>\r\n");
end.append("    </td>\r\n");
end.append("  </tr> \r\n");
end.append("</table>\r\n");

%>
<%-- PRC 198588 - Remove the attachment section
end.append("<img src=\"images/dark-blue.png\" width=\"778\" height=\"25\" style=\"margin-top: 20px;\" />\r\n");
end.append("<div style=\"text-align:center;font-size: 24pt; font-family: 'Times New Roman';color: #0061a2; margin: 20px 0px;\">Attachment</div>\r\n");
end.append("<p style=\"font-family: Arial; font-size: 8.25pt; margin-top:0px;\">Attach a list with the name and business address of each location at which you conduct business and each of the dealer's and manufacturer's numbers issued by the Texas Parks and Wildlife Department (TPWD).</p>\r\n");

end.append("  <table style=\"width: 778px; padding:0px; margin:0px;\">\r\n");

if(ds.size() > 0){
    try{
        String[] businessNames      = new String[ ds.size() ];
        String[] addresses          = new String[ ds.size() ];
        String[] licenses           = new String[ ds.size() ];
        if (isDefined(request.getParameter("formSubmitted"))){
            businessNames           = request.getParameterValues("businessName");
            licenses                = request.getParameterValues("theLicense");
            addresses               = request.getParameterValues("address");
        }
        Dealership dealer = new Dealership();
    
        for (int i = 0 ; i < 2 ; i++){
            dealer = (Dealership) ds.get(i);

            end.append("  <tr>\r\n");
            end.append("      <td style=\"height: 20px; vertical-align: bottom;\">");
            end.append(       nvl(businessNames[i],"<input type=\"text\"  name=\"businessName\" class=\"license\" style=\"width: 510px;\" />\r\n")  );
            end.append("      </td>\r\n");
            end.append("      <td>&nbsp;&nbsp;&nbsp;&nbsp;</td>\r\n");
            end.append("      <td style=\"vertical-align: bottom;\">");    
            end.append(       nvl(licenses[i],"<input type=\"text\" name=\"theLicense\" class=\"license\" placeholder=\"license #\" style=\"width: 300px;\" />\r\n")  );
            end.append("      </td>\r\n");
            end.append("  </tr>\r\n");
            end.append("  <tr>\r\n");
            end.append("      <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt; width: 550px;\">Name of Business</td>\r\n");
            end.append("      <td>&nbsp;</td>\r\n");
            end.append("      <td style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">TPWD Dealer's and Manufacturer's Number</td>\r\n");
            end.append("  </tr>\r\n");
            end.append("  <tr>\r\n");
            end.append("      <td colspan=\"3\" style=\"height: 20px;vertical-align: bottom;\" >");
            end.append(       nvl(addresses[i],"<input type=\"text\"  name=\"address\" class=\"license\" style=\"width: 773px;\" />\r\n")  );
            end.append("      </td>\r\n");
            end.append("  </tr>\r\n");
            end.append("  <tr>\r\n");
            end.append("      <td colspan=\"3\" style=\"border-top:1px solid #6594c5; font-family:Arial; font-size:6.75pt;\">Address, Street, City, State, ZIP Code</td>\r\n");
            end.append("  </tr>    \r\n");
            end.append("  <tr><td colspan=\"3\">&nbsp;</td></tr>\r\n");

        }
    }catch (Exception e){
        end.append("jac in the table loop: " + e.toString());
    }
} else {
    end.append("<tr><td colspan=\"3\" style=\"text-align: center;\">&nbsp;</td></tr>");
}

end.append("</TABLE>\r\n");
--%><%
end.append("   <div id=\"version\" style=\"text-align: right; font-style: italic; font-size: 10px;\">50-259 * 05-15/10</div>\r\n");
end.append("</div><!--container -->\r\n");
end.append("</div><!--page holder -->\r\n");

if ( notDefined( request.getParameter("formSubmitted") ) ){
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


if ( isDefined(request.getParameter("formSubmitted") ) ){ 
  String thisPage = "50-259.jsp";
%>
  <%@ include file="_yearly.jsp"%>
<%
}//if (isDefined(request.getParameter("formSubmitted")))

    try{
     out.print(start.toString() + middle.toString() + end.toString()); 
    } catch(Exception e){SITLog.error(e, "\r\nProblem writing StringBuffers for 50_267.jsp\r\n");} 
%>
