<%@ page import="act.sit.*" %><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");

    Payments    payments    = (Payments) session.getAttribute("payments");
    if ( payments != null ) payments.removeAll();
%>{ "status":"OK" }
