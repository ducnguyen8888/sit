<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>

<%
  session.setAttribute( "forwarded",   "true"       );
  session.setAttribute( "client_id",   "147000000"   );
  session.setAttribute( "client_name", "Galveston"    );
  session.setAttribute( "client_url",  "galveston.jsp" );
  session.setAttribute( "imageName",   "galveston"     );
%>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Login</title>
</head>
<body>
<jsp:forward page="login.jsp">
	<jsp:param name="forwarded"   value="true"     /> 
	<jsp:param name="client_id"   value="147000000" /> 
	<jsp:param name="client_name" value="Galveston"  /> 
</jsp:forward>
	
</body>
</html>