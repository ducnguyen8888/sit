<%@ page import="java.util.*,act.util.*,java.sql.*,java.math.*,java.text.*" 
%><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");

    SITConfiguration p = null;
    try {
        p = new SITConfiguration(pageContext, "sitDallas");
        %>P: <%= p.toString() %> <%
        %><li> Client: <%= p.clientId %></li><%
        %><li> DataSource: <%= p.dataSource %></li><%
    } catch (Exception exception) {
        %><li> Exception: <%= exception.toString() %></li><%
        try {
            %>Base Directory: <%= p.getBaseDirectory() %> <%
        } catch (Exception subException) {
            %><li> Exception: <%= subException.toString() %></li><%
        }
    }
%>
