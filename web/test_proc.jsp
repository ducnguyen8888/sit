<%@ page import="java.util.*, java.io.*, java.sql.*, java.lang.StringBuffer" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1.
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0.
    response.setHeader("Expires", "0"); // Proxies.
%>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<%
    PreparedStatement ps         = null;
    CallableStatement cs         = null;
    ResultSet         rs         = null;
    Connection        conn = null;

    conn = act.util.Connect.open("jdbc/sit_dev");

  // long client_id = 92000000;
  // String can = "H46509300H000009";
  long client_id = 79000000;
  String can = "H000001";
  String year = "2007";
String month = "12";
    //Connection connection = act.util.Connect.open("jdbc:oracle:thin:@ares:1521:actd", "act", "manager");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>testing</title>
    <style>
        td {font-family: sans-serif;}
    </style>
</head>
<body>
  
  <table>
        <tr>
            <td style='padding: 6px;'>can</td>
            <td style='padding: 6px;'>year</td>
            <td style='padding: 6px;'>month</td>
            <td style='padding: 6px; text-align: right; font-weight: bold;'>msale_levy</td>
            <td style='padding: 6px; text-align: right;'>msale_levbal</td>
            <td style='padding: 6px; text-align: right;'>msale_penbal</td>
            <td style='padding: 6px; text-align: right; font-weight: bold;'>mfine_levy</td>
            <td style='padding: 6px; text-align: right;'>mfine_levbal</td>
            <td style='padding: 6px; text-align: right;'>mfine_penbal</td>
            <td style='padding: 6px; text-align: right; font-weight: bold;'>mnsf_levy</td>
            <td style='padding: 6px; text-align: right;'>mnsf_levbal</td>
            <td style='padding: 6px; text-align: right;'>mnsf_penbal</td>
            <td style='padding: 6px; text-align: right;'>AMOUNT_DUE</td>
        </tr>
<%

    try {
        ((oracle.jdbc.OracleConnection)conn).setSessionTimeZone(TimeZone.getDefault().getID());
        cs = conn.prepareCall("{ ?=call vit_utilities.get_amount_due_by_month(?,?,?,?) }");
        //cs = conn.prepareCall("{ ?=call vit_utilities.get_amount_due_by_month(client_id=>?,can=>?,year=>?) }");
        cs.registerOutParameter(1,oracle.jdbc.OracleTypes.CURSOR);
        cs.setLong  (2, client_id);
        cs.setString(3, can);
        cs.setString(4, year);
        cs.setString(5, month);
        cs.execute();
        rs = (ResultSet) cs.getObject(1);
         ResultSetMetaData rsmd = rs.getMetaData();
         //out.print("<tr><td>");
         //for(int i = 1; i <= rsmd.getColumnCount();i++){
         //   out.print(rsmd.getColumnName(i)+"<br>");
         //}  
         //out.print("</td></tr>");
       while (rs.next()) { 
           out.print("<tr>");
           out.print("    <td>" + rs.getString("can") + "</td>");
           out.print("    <td>" + rs.getString("year") + "</td>");
           out.print("    <td>" + rs.getString("month") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("msale_levy") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("msale_levybal") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("msale_penbal") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("mfine_levy") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("mfine_levbal") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("mfine_penbal") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("mnsf_levy") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("mnsf_levbal") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("mnsf_penbal") + "</td>");
           out.print("    <td style='padding: 3px; text-align: right;'>" + rs.getString("AMOUNT_DUE") + "</td>");
           out.print("</tr>");
       }
        rs.close();    rs   = null;
    } catch(Exception e){
        out.print("exception: " + e.toString());
    } finally {
        if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
        if ( cs   != null ) { try { cs.close();   } catch (Exception e) {} cs   = null; }
    }



//try{
//    ps=connection.prepareStatement("select client_id, code, description, other from client_prefs where rownum < 100");
//    rs=ps.executeQuery();
//    while(rs.next()){
//        out.print("<tr>\r\n");
//        out.print("    <td>"+rs.getString(1)+"</td>\r\n");
//        out.print("    <td>"+rs.getString(2)+"</td>\r\n");
//        out.print("    <td>"+rs.getString(3)+"</td>\r\n");
//        out.print("    <td>"+rs.getString(4)+"</td>\r\n");
//        out.print("</tr>\r\n");
//    }
//} catch(Exception e){out.print("Exception: " + e.toString());
//} finally {
//    try { if (rs != null) rs.close(); } catch (Exception e) { out.print("Exception: " + e.toString());}
//    rs = null;
//    try {if (ps != null) ps.close(); } catch (Exception e) { out.print("Exception: " + e.toString()); }
//    ps = null;
//}
%>

</table>


<script src="assets/js/jquery.min.js"></script> 
<script>
    $(document).ready(function() {

       // $("button#btnNext").click(function(e){ // next
       //     e.preventDefault();
       //     e.stopPropagation();
       //     var theForm = $("form#navigation");
       //     theForm.children("input#can2").prop("value", can);
       //     theForm.children("input#year2").prop("value", year);
       //     theForm.children("input#month2").prop("value", month);
       //     theForm.prop("action", "confirmTotals.jsp");
       //     theForm.submit();
       // });
//
       // $("table#recentsTable a").click(function(e) { // recents
       //     e.preventDefault();
       //     e.stopPropagation();
       //     var can = $(this).text();
       //     var name = $(this).parent().children("#sidebarRecent").text();
       //     var theForm = $("form#navigation");
       //     theForm.children("input#can2").prop("value", can);
       //     theForm.children("input#name2").prop("value", name);
       //     theForm.prop("action", "yearlySummary.jsp");
       //     theForm.submit();
       // }); 

    });//doc ready
</script>
</body>
</html>

<% conn.close(); conn = null; %>




