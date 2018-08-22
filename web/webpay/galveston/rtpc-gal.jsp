<%@ page import="java.util.*,java.util.regex.*,act.util.*,java.sql.*,java.text.*,act.log.*,act.log.epay.*,java.util.logging.*" 
%><%!
    String      configurationName   = "sitGalveston";
    boolean     isInteractive       = false;

    boolean     makeDBChanges       = true;
    boolean     rollbackChanges     = false;
%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");

    AppConfiguration configuration = new AppConfiguration(pageContext,configurationName);

    String      clientId        = configuration.clientId;
    String      dataSource      = configuration.dataSource;

    // This will work only after the included class-text files are made into actual Classes
    // If page is saved any prior transactions are un-usable due to notice class being recompiled
    Map cache = (Map) application.getAttribute("RTPC-SIT");
    if ( cache == null ) application.setAttribute("RTPC-SIT",(cache=new Hashtable()));

    RTPCNotice rtpcNotice = null;
    String param = listParameters(request);
    PostbackNotice notice = null;//new SITChaseNotice(clientId, request);

    // This "report" functionality should be in a separate page but due to the
    // RTPC based classes being presently defined as inner classes we must have
    // this within the same page to access the class objects. Once the RPTC
    // classes are created as external classes this should be moved to it's own
    // page with access control.
    if ( isDefined(request.getParameter("clear")) ) {
        cache.clear();
        %>Cache cleared<%
        return;
    } else if ( isDefined(request.getParameter("report")) ) {
        String [] keys = (String []) cache.keySet().toArray(new String[0]);
        %><!doctype>
        <html>
        <head>
            <script src="js/jquery-3.1.1.min.js"></script>
            <style> button { padding: 2px; margin-right: 5px; } 
                    h4 { background-color: #e8e8e8; padding: 5px 10px 0px; margin: 0px; font-weight: normal; overflow-wrap: normal; }
                    h4 pre {  white-space: pre-wrap;       /* css-3 */
                             white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */
                             white-space: -pre-wrap;      /* Opera 4-6 */
                             white-space: -o-pre-wrap;    /* Opera 7 */
                             word-wrap: break-word;       /* Internet Explorer 5.5+ */
                             }

                    h6.error { background-color: pink; padding: 20px; margin: 0px; font-weight: normal; }
                    button.toggleButton { display: none; }
                    button { display: inline-block; }
                    .title { font-style: italic; }
                    div.header { position:fixed; top:0px; left:0px; right: 0px; height: 40px;
                                background-color: #d7d7d7; padding: 2px 15px; color: darkblue; border-bottom: 2px solid darkblue;
                                font-size: 16px; font-style: italic;
                                }
                    div.header h3 { margin: 0px; padding: 0px; 
                                }
                    div.header h3 .note { font-size: 13px; font-weight: normal;
                                }
                    div.content { position:fixed; top:50px; left:0px; right: 0px; bottom: 0px; overflow: auto; padding: 0px 10px 30px;
                                }
                                div.content pre { margin: 2px 0px 4px; }
            </style>
            <script>
                $(function() {
                    $(".toggleButton").click(toggleDetail);;
                    $(".toggleButton").show().click();
                });
                function toggleDetail() {
                    var block = $("#" + $(this).prop("id").replace("button","block")).toggle();
                    if ( block.is(":visible") ) 
                        $(this).html("[&ndash;]");
                    else
                        $(this).html("[+]");
                }
            </script>
        </head>
        <body>
        <%
        java.lang.management.RuntimeMXBean rb = java.lang.management.ManagementFactory.getRuntimeMXBean();
        %>
        <div class="header">
            <h3> SIT Payment Postback &ndash; <span class="note">Client <%= clientId %> &nbsp; &nbsp; DataSource: <%= dataSource %></span> </h3>
            Server Running Since: <%= (new java.util.Date(rb.getStartTime())).toString() %>
        </div>
        <div class="content">
        <%
        if ( keys.length == 0 ) {
            %>No transactions were found in the transaction cache<%
        } else {
            int blockIndex = 0;
            Arrays.sort(keys,Collections.reverseOrder());
            for ( String key : keys ) {
                blockIndex++;
                String recordId = key;
                String blockToggle = "<button class=\"toggleButton\" id=\"button-" + blockIndex + "\">[+]</button>";
                Exception parseException = null;
                try {
                    String [] control = key.split("-\\?")[0].split("-");
                    String client = control[0];
                    String datetime = "<span class='title'>" + (new java.util.Date(Long.parseLong(control[1]))).toString() + "</span>";
                    try {
                        rtpcNotice = (RTPCNotice) cache.get(key);
                        recordId = datetime + "<pre style='margin-top:0px;color:darkblue;'>" + rtpcNotice.postbackNotice.toString(true)+"</pre>";
                    } catch (ClassCastException exception) {
                        //blockToggle = "";
                        recordId = datetime + "<pre style='margin-top:0px;color:darkblue;'>" + key.split("-\\?")[1] +"</pre>";
                    }
                } catch (Exception exception) {
                    parseException = exception;
                    //blockToggle = "";
                }

                %><h4> <%= blockToggle %><%= recordId %> </h4><%
                if ( parseException != null ) {
                    %><hr><h6 class="error"> <%= parseException.toString() %> </h6><%
                }
                if ( rtpcNotice != null ) {
                    %><pre id="block-<%=blockIndex%>"><%= rtpcNotice.toString() %></pre><%
                }
            }
        }
        %></div></body></html><%
        return;
    } else {
        if ( param != null && param.length() > 10 && ! cache.containsKey(param) ) {
            notice = new SITChaseNotice(clientId, request);
            rtpcNotice = new RTPCNotice(request,dataSource,notice);

            // Set our database updates/commits
            rtpcNotice.reportOnly    = ! makeDBChanges;
            rtpcNotice.commitChanges = ! rollbackChanges;

            // Start processing and give us a 2 second head start
            rtpcNotice.start();
            String key = clientId + "-" + System.currentTimeMillis() + "-" + param;
            try { cache.put(key,rtpcNotice); } catch (Exception ignore) {}
            try { Thread.sleep(2000); } catch (Exception ignore) {}
        }
        if ( ! isInteractive ) {
            %>OK<%
            return;
        }
    }

    %><!doctype>
    <html>
    <head>
        <script src="js/jquery-3.1.1.min.js"></script>
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
<%@ include file="rtpcClasses/PostbackNoticeClass.txt"%>
<%@ include file="rtpcClasses/SITChaseNoticeClass.txt"%>
<%@ include file="rtpcClasses/RTPCNoticeClass.txt"%>
<%@ include file="rtpcClasses/TransactionClass.txt"%>
<%!
    public String nvl(String value) { return (value != null ? value : ""); }
    public boolean isDefined(String value) { return value != null && value.length() > 0; }
    public boolean notDefined(String value) { return value == null || value.length() == 0; }
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
%>
