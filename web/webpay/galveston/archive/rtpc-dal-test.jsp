<%@ page import="java.util.*,java.util.regex.*,act.util.*,java.sql.*,java.text.*,act.log.*,act.log.epay.*,java.util.logging.*" 
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

    boolean     isInteractive   = false;

    boolean     makeDBChanges   = false;
    boolean     rollbackChanges = false;

    String      clientId        = "7580";
    String      dataSource      = "jdbc/sit";
%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");


    RTPCNotice rtpcNotice = null;
    String param = listParameters(request);
    PostbackNotice notice = new SITChaseNotice(clientId, request);

    if ( param != null && param.length() > 10 && ! cache.containsKey(param) ) {
        rtpcNotice = new RTPCNotice(request,dataSource,notice);

        // Set our database updates/commits
        rtpcNotice.reportOnly    = ! makeDBChanges;
        rtpcNotice.commitChanges = ! rollbackChanges;

        // Start processing and give us a 2 second head start
        rtpcNotice.start();
        try { cache.put(param,rtpcNotice); } catch (Exception e) {}
        try { Thread.sleep(2000); } catch (Exception e) {}
    }
    if ( ! isInteractive ) {
        %>OK<%
        return;
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
<%@ include file="rtpcClasses/PostbackNoticeClass.txt"%>
<%@ include file="rtpcClasses/SITChaseNoticeClass.txt"%>
<%@ include file="rtpcClasses/RTPCNoticeClass.txt"%>
<%@ include file="rtpcClasses/TransactionClass.txt"%>
