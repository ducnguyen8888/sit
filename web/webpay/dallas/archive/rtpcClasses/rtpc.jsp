<%@ page import="java.util.*,java.util.regex.*,act.util.*,java.sql.*,java.text.*,act.log.*,java.util.logging.*" 
%><%!
    public String listParameters(javax.servlet.http.HttpServletRequest request) {
        java.util.Map parameters = (java.util.Map) request.getParameterMap();
        String [] keys = (String []) parameters.keySet().toArray(new String[0]);
        java.util.Arrays.sort(keys);

        if ( keys.length == 0 ) return "No parameters specified";

        StringBuffer buffer = new StringBuffer();
        for ( String key : keys ) {
            String [] values = (String[])parameters.get(key);
            for ( String value : values ) {
                buffer.append("&" + key + "=" + value);
            }
        }
        buffer.replace(0,1,"?");

        return buffer.toString();
    }

    String clientId     = "7580";
    String dataSource   = "jdbc/sit_test";
%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");


    RTPCNotice rtpcNotice = null;
    String param = listParameters(request);
    PostbackNotice notice = new SITChaseNotice(clientId, request);

    if ( true ) {
        if ( param != null && param.length() > 10 && ! cache.containsKey(param) ) {
            rtpcNotice = new RTPCNotice(request,dataSource,notice);

            // Ensure our upates aren't actually made, this is for testing
            rtpcNotice.reportOnly    = false;
            rtpcNotice.commitChanges = false;

            // Start processing and give us a 2 second head start
            rtpcNotice.start();
            try { Thread.sleep(2000); } catch (Exception e) {}
        }
    }
    %><!doctype>
    <html>
    <head>
        <script src="../../../js/jquery-3.1.1.min.js?Date.now()"></script>
        <script>
            $(function() {
                $("#submitToServer").click(setUrl);
                $("#clearRtpc").click(clearRtpc);
            });
            function clearRtpc() {
                $("#notice").val("");
            }
            function setUrl() {
                var value = $("#notice").val();
                value = value.replace(/([^\?]*\?|[\s\r\n]*)/,"");
                window.location = "<%= request.getRequestURI() %>?" + value;
            }
        </script>
    </head>
    <body>
    <br>
    <textarea id="notice" cols="60" rows="6"><%= param %></textarea><br><br>
    <button id="submitToServer" name="x">Post Notice</button>
    <button id="clearRtpc" name="clear">Clear Notice</button>
    <br><hr>
    <pre><%= (notice == null ? "" : notice.toString()) %></pre>
    <br><hr>
    <pre><%= (rtpcNotice == null ? "" : rtpcNotice.toString()) %></pre>
    <br><hr>

    </body>
    </html>
    <%


%><%!
public Map cache = new Hashtable();
%>
<%@ include file="PostbackNoticeClass.txt"%>
<%@ include file="SITChaseNoticeClass.txt"%>
<%@ include file="RTPCNoticeClass.txt"%>
<%@ include file="TransactionClass.txt"%>
