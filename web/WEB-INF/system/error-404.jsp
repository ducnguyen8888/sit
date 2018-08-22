<%@ page import="java.io.*,java.util.*"%><%--

--%><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma" , "no-cache");
	response.setDateHeader("Expires", 0);

    Integer   errorStatusCode = (Integer) request.getAttribute("javax.servlet.error.status_code");
    String    errorMessage    = (String) request.getAttribute("javax.servlet.error.message");

    String    errorPage       = (String) request.getAttribute("javax.servlet.error.request_uri");

    Exception errorThrown = null;
%><!DOCTYPE html>
<html lang="en" ng-app="WebsitePayment" ng-controller="PaymentController">
<head>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/font-awesome-4.7.0/css/font-awesome.min.css">
    <style> 
        html { margin: 0px; padding: 0px; margin-bottom: 50px; font-family: Arial; font-size: 14px; }
        body { margin: 0px; padding: 0px; }
        .header { }
        .content { margin-left: 45px; }

        h2 { color: #002157; }
        a { color: #002157; font-size: 1.3em; }
        .content h4 { margin: 20px 0px 10px 0px; font-size: 1.1em; padding: 5px 3px;
                    border-bottom: 1px solid #002157;border-top: 1px solid #002157; color: #002157; 
                    background-color: #f5f5f5;
                    }

        .content ul { margin: 0px; }
        .content ul > li { margin-left: -35px; padding-left: 0px; margin-top: 8px; }
        .xcontent ul > ul > li { padding-left: -20px; margin-top: 8px; background-color: yellow; }
        .content ul h5 { margin-left: -15px; }

        .content .message { font-size: 1.2em; color: red; }
        .content div.fa { display: inline-block; width: 25px; }

        .page-banner { background-color:#002157;height:50px;width:100%; margin-bottom: 0px; }
        .error-status-code { display:inline-block; width: 150px; font-size: 78px; color: #5d5d5d; vertical-align: top;font-weight: bold; 
                            line-height: 60px; text-align: left; }
        .error-details { display:inline-block; width: auto; font-size: 16px; color: #002157; border-left: 2px solid darkgrey; padding-left: 14px; }
        .error-message { font-size: 48px; color: #5d5d5d; color: #002157; }
        .error-details .message { font-size: 1.0em; color: red; margin-top: 15px; }

        .error-header { padding-left: 20px; }
        .error-header label { display: inline-block; width: 80px; margin-top:10px; }
        .error-header hr { margin: 0px; height: 2px; background-color: black; }
        .error-details div { margin-bottom: 5px; }
        .error-header > div { padding-top: 10px; padding-bottom: 10px; xpadding-left: 10px; }

        .error-details div { min-width: 300px; }

        pre { font-size: 16px; padding-left: 40px; }
        li { list-style: none; margin-top: 6px; margin-bottom: 8px; }
    </style>
</head>
<body>
<div class="header">
	<div class="page-banner"></div>
    <div class="error-header" style="background-color: #f5f5f5;">
        <div class="error-status-code"> <%= errorStatusCode %> </div>
        <div class="error-details">
            <div class="error-message"> <%= errorMessage %> </div>
            <div style="font-size: 25px;">
                <div> <label> Requested Page: </label> <%= errorPage %> </div>
                <div class="message">
                    The page you requested was not found
                </div>
            </div>
        </div>
    </div>
</div>
<pre>
Context Path: <%= request.getContextPath() %>
Application:  <%= application.getRealPath("test.jsp") %>
</pre>
<div class="content">
    <%
    if ( errorPage != null ) {
        try {
            String applicationPath = application.getRealPath("");
            String applicationContext = request.getContextPath();
            String query = request.getQueryString();
            query = (query == null ? "" : "?" + query);


            String requestedDirectory = errorPage.replaceAll("([^/\\\\]*)$","")
                                                 .replaceAll("^([/\\\\][^/\\\\]*)","");
            String parentDirectory = applicationContext + requestedDirectory.replaceAll("([^/\\\\]*[/\\\\]{1})$","");

            // This will ensure we have the last valid directory for the request
            String directoryPath = application.getRealPath(requestedDirectory);
            while ( directoryPath == null ) {
                requestedDirectory = requestedDirectory.replaceAll("([^/\\\\]*[/|\\\\]{0,1})$","");
                directoryPath = application.getRealPath(requestedDirectory);
            }
            File [] files = (new File(application.getRealPath(requestedDirectory))).listFiles();

            %><h2> Reference Path: <%= request.getContextPath() %><%= requestedDirectory %> </h2><%
            if ( files != null && files.length > 0 ) {
                Arrays.sort(files);

                if ( ! requestedDirectory.matches("[/\\\\]") ) {
                    %><li style="list-style:none;"> 
                        <div class="fa fa-folder-open-o"></div><a href="<%= parentDirectory+query %>">[parent directory]</a>
                    </li><%
                }

                boolean directoriesFound = false;
                %><div style="min-width:250px;float:left;display:inline-block;margin-right:50px;"><h4> Sub-Directories: </h4><%
                for ( File file : files ) {
                    if ( ! file.isDirectory() ) continue;
                    if ( ! directoriesFound ) {
                        directoriesFound = true;
                    }
 
                    String linkPath = applicationContext + requestedDirectory + file.getName();
                    %><li> <div class="fa fa-folder-open-o"></div><a href="<%= linkPath+query %>"><%= file.getName() %></a></li><%
                }
                %></div><%

                boolean filesFound = false;
                %><div style="min-width:350px;float:left;display:inline-block;"><h4> Alternative Files: </h4><%
                for ( File file : files ) {
                    if ( file.isDirectory() ) continue;
                    if ( ! filesFound ) {
                        filesFound = true;
                    }

                    String linkPath = applicationContext + requestedDirectory + file.getName();
                    if ( file.getName().matches(".*(\\.jsp)$") ) {
                        %><li> <div class="fa fa-file-code-o"></div><a href="<%= linkPath+query %>"><%= file.getName() %></a></li><%
                    } else if ( file.getName().matches(".*(\\.html)$") ) {
                        %><li> <div class="fa fa-file-code-o"></div><a href="<%= linkPath %>"><%= file.getName() %></a></li><%
                    } else {
                        %><li> <div class="fa fa-file-o"></div><a href="<%= linkPath %>"><%= file.getName() %></a></li><%
                    }
                }
                %></div><%

            }
        } catch (Exception exception) {
            %><li> Exception: <%= exception.toString() %> <%
        }
    }
    %>
</div>
</body>
</html>
