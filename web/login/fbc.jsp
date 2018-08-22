<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>

<%
  session.setAttribute("forwarded", "true");
  session.setAttribute("client_id", "79000000");
  session.setAttribute("client_name", "Fort Bend");
  session.setAttribute("client_url", "fbc.jsp");
  session.setAttribute("imageName", "fbc");
%>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Login</title>
</head>
<body>
<jsp:forward page="login.jsp">
	<jsp:param name="forwarded"    value="true"      /> 
	<jsp:param name="client_id"    value="79000000"  /> 
	<jsp:param name="client_name"  value="Fort Bend" /> 
</jsp:forward>
	
</body>
</html>