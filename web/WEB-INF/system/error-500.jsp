<%@ page language="java" 
	contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1" 

	isErrorPage="true"
%><%--

--%><%!

    /** Name of the client error page, if this page exists the error will be redirected to that page.
     *
     * If this is a client directory and the specified file exists the error will be forwarded to
     * that client error page to handle the error. If that error page doesn't exist in the client
     * directory, or this isn't a client directory, then this page will handle the error.
     */
    String clientErrorPageName = "/target.jsp";
%><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma" , "no-cache");
	response.setDateHeader("Expires", 0);


    Integer   errorStatusCode = (Integer) request.getAttribute("javax.servlet.error.status_code");
    String    errorMessage    = (String) request.getAttribute("javax.servlet.error.message");

    String    errorPage       = (String) request.getAttribute("javax.servlet.error.request_uri");

    Throwable errorThrown     = (Throwable) request.getAttribute("javax.servlet.error.exception");
              errorThrown     = exception; // Available by virtue of this being declared an error page



    // Check to see request is for a client and a client error page exists
    String clientDirectory = (errorPage == null ? "" : errorPage.replaceAll("^/[^/]{1,}(/[^/]{1,})(/.*){0,}","$1"));
    String clientErrorPage = clientDirectory + clientErrorPageName;
    if ( application.getRealPath(clientErrorPage) != null ) {
        pageContext.forward(clientErrorPage);
        return;
    }

%><!DOCTYPE html>
<html lang="en">
<head>
	<style>
        body { margin: 0px; font-family: Arial; font-size: 14px; padding-bottom: 30px; }
        .page-banner { background-color:#002157;height:50px;width:100%; margin-bottom: 0px; }
        .error-status-code { overflow: hidden; display:inline-block; width: 140px; font-size: 78px; color: #5d5d5d; vertical-align: top;font-weight: bold; line-height: 60px; }
        .error-details { display:inline-block; width: auto; font-size: 16px; color: #002157; border-left: 2px solid #002157; padding-left: 14px; }
        .error-message { font-size: 48px; color: #5d5d5d; color: #002157; }

        .error-header { padding-left: 30px; }
        .error-header label { display: inline-block; width: 80px; margin-top:10px; }
        .error-header hr { margin: 0px; height: 2px; background-color: black; margin-right: 30px; }
        .error-header div { xmargin-bottom: 5px; }
        .error-header > div { padding-top: 10px; padding-bottom: 10px; padding-left: 10px; }

        .error-details div { min-width: 500px; }

        .error-description { padding-left: 0px; color: #002157; }
        hr { margin: 0px; color: #002157; height: 2px; background-color: #002157;  }
        h4 { margin: 0px 40px -10px; padding-top: 4px; font-style: italic; font-size: 17px; color: #002157; border-top: 1px solid #002157; }

        pre { font-size: 16px; padding-left: 40px; }
	</style>
</head>
<body>
	<div class="page-banner"></div>
    <div class="error-header">
        <div class="error-status-code">
            <%= errorStatusCode %>
        </div>
        <div class="error-details">
            <div class="error-message">
                <%= errorMessage %>
            </div>
            <div style="font-size: 25px;">
                <div>
                    <label> Page: </label> <%= errorPage %>
                </div>
                <div>
                <label> Error: </label> <%= (errorThrown == null ? "" : errorThrown.getClass().getName()) %>
                </div>
            </div>
        </div>
    </div>
    <hr>
    <% if ( errorThrown != null ) { %>
    <div class="error-description">
        <pre><%= errorThrown.getMessage() %></pre>
    </div>
    <% } %>
    <h4> Error Trace: </h4>
    <pre><%= getErrorTrace(errorThrown) %></pre>
</body>
</html>
<%!
    /** Returns the exception error stack trace
     * @param throwableError the error to return the stack trace for
     * @return String the stack track of the exception
     */
    public String getErrorTrace(Throwable throwableError) {
        if ( throwableError == null ) return null;

        java.io.ByteArrayOutputStream baos = null;
		java.io.PrintStream originalErrorStream = System.err;
		try {
            baos = new java.io.ByteArrayOutputStream();

            // Set the error stream to use our byte array
			java.io.PrintStream ps = new java.io.PrintStream(baos);
			System.setErr(ps);

            // Output the stack trace, this outputs to the error stream
            throwableError.printStackTrace();
			System.err.flush();
		} catch (Throwable e) {
		} finally {
            // Reset our error stream
			System.setErr(originalErrorStream);
			originalErrorStream = null;
		}

        return baos.toString();
    }
%>
