<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>

<%
  session.setAttribute( "forwarded",   "true"       );
  session.setAttribute( "client_id",   "7580"   );
  session.setAttribute( "client_name", "Dallas"    );
  session.setAttribute( "client_url",  "dallas.jsp" );
  session.setAttribute( "imageName",   "dallas"     );
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
	<jsp:param name="client_id"   value="7580" /> 
	<jsp:param name="client_name" value="Dallas"  /> 
</jsp:forward>
	
</body>
</html>