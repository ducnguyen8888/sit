<%@ page import="java.util.*" 
%><%!
boolean notDefined(String value) { return value==null || value.length() == 0; }
%><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");


    //  Page should not be requested directly
    if ( notDefined(request.getHeader("REFERER")) ) {
        session.removeAttribute("PDS-Payment-testPayment");
        session.removeAttribute("PDS-Payment-clientId");
        session.removeAttribute("PDS-Payment-datasource");
        session.removeAttribute("PDS-Payment-url-clientRoot");
        session.removeAttribute("PDS-Payment-url-accountSearch");
        response.setStatus(404);
        return;
    }



	%>{ "status": "OK" }<%
	if ( session.isNew() ) session.invalidate();
	if ( true ) return;
%>
