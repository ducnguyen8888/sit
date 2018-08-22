<%@ page import="java.util.*, java.io.*, java.sql.*, java.lang.StringBuffer, act.sit.*" %>
<%@ page import="java.util.concurrent.ExecutionException" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1.
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0.
    response.setHeader("Expires", "0"); // Proxies.
%><%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<jsp:useBean  id="ds" class="act.sit.Dealerships"  scope="session"/>
<jsp:useBean  id="d" class="act.sit.Dealership"  scope="session"/>
<jsp:useBean  id="payments" class="act.sit.Payments"  scope="session"/>
<jsp:useBean  id="payment" class="act.sit.Payment"  scope="session"/>
<jsp:useBean  id="recents" class="act.sit.Recents" scope="session"/>




<%
    PreparedStatement ps = null;
    ResultSet rs = null;
    Connection connection = null;

    connection = act.util.Connect.open("jdbc/sit");
    //Connection connection = act.util.Connect.open("jdbc:oracle:thin:@ares:1521:actd", "act", "manager");
    SITAccount      sitAccount      = null;
    SITUser         sitUser         = null;

    try {
        sitAccount = new SITAccount("jdbc/sit","7580","dctest","Tex@s123");
        sitAccount.isValid();
        out.println("Status: "+ sitAccount.isValid());

    } catch (Exception e){
        out.println(e.toString());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>testing</title>
    <style>

    </style>
</head>
<body>
  
  <table>
        <tr>
            <td>client_id</td>
            <td>code</td>
            <td>description</td>
            <td>other</td>
        </tr>


<%
try{
    ps=connection.prepareStatement("select client_id, code, description, other from sit_codeset where rownum < 100");
    rs=ps.executeQuery();
    while(rs.next()){
        out.print("<tr>\r\n");
        out.print("    <td>"+rs.getString(1)+"</td>\r\n");
        out.print("    <td>"+rs.getString(2)+"</td>\r\n");
        out.print("    <td>"+rs.getString(3)+"</td>\r\n");
        out.print("    <td>"+rs.getString(4)+"</td>\r\n");
        out.print("</tr>\r\n");
    }
} catch(Exception e){out.print("Exception: " + e.toString());
} finally {
    try { if (rs != null) rs.close(); } catch (Exception e) { out.print("Exception: " + e.toString());}
    rs = null;
    try {if (ps != null) ps.close(); } catch (Exception e) { out.print("Exception: " + e.toString()); }
    ps = null;
}
%>

</table>

<script src="assets/js/jquery.min.js"></script> 
<script>
    $(document).ready(function() {

        $("button#btnNext").click(function(e){ // next
            e.preventDefault();
            e.stopPropagation();
            var theForm = $("form#navigation");
            theForm.children("input#can2").prop("value", can);
            theForm.children("input#year2").prop("value", year);
            theForm.children("input#month2").prop("value", month);
            theForm.prop("action", "confirmTotals.jsp");
            theForm.submit();
        });

        $("table#recentsTable a").click(function(e) { // recents
            e.preventDefault();
            e.stopPropagation();
            var can = $(this).text();
            var name = $(this).parent().children("#sidebarRecent").text();
            var theForm = $("form#navigation");
            theForm.children("input#can2").prop("value", can);
            theForm.children("input#name2").prop("value", name);
            theForm.prop("action", "yearlySummary.jsp");
            theForm.submit();
        }); 

    });//doc ready
</script>
</body>
</html>

<% connection.close(); connection = null; %>




