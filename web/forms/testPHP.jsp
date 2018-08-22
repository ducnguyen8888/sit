<%@ page import="java.util.*, java.io.*,java.sql.*, java.lang.StringBuffer, act.sit.Dealerships, act.sit.Dealership, java.util.logging.*, act.log.Logs, act.util.Sysutil, act.log.SITLog" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1.
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0.
    response.setHeader("Expires", "0"); // Proxies.
    session.setMaxInactiveInterval(60*20); // 20 minutes
%>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Document</title>
</head>
<body>
  
<form action="http://apollo:7003/act_webdev/php/test2.php" method="post">
  <input type="text" value="SIT_08052016115051.html" name="file">
<button type="submit">submit</button>
</form>



</body>
</html>