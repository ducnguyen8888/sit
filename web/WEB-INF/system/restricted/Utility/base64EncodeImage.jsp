<%@ page import="java.util.Base64,java.io.InputStream,java.text.DecimalFormat" 
%><%--
    Takes user specified image file and converts it to Base-64 encoding
    
    Useful for embedding images directly into webpages



    The servlet must include the multipart annotations. Alternately the multipart
    information can be included in the web.xml file, and mapped directly to a
    JSP file. The multipart settings must be included as part of a <servlet>
    tag, if a JSP file is to be used then the JSP file must be configured
    to map to the servlet where the multipart settings are configured.

    <servlet>   
        <servlet-name>uploadfile</servlet-name>
        <jsp-file>/WEB-INF/system/restricted/Utility/base64EncodeImage.jsp</jsp-file>
        <multipart-config>
            <location>/temp</location>
            <max-file-size>20848820</max-file-size>
            <max-request-size>418018841</max-request-size>
            <file-size-threshold>1048576</file-size-threshold>
        </multipart-config>
    </servlet>
    <servlet-mapping>
        <servlet-name>uploadfile</servlet-name>
        <url-pattern>/restricted/Utility/base64EncodeImage.jsp</url-pattern>
    </servlet-mapping>


--%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");

    DecimalFormat numberFormat = new DecimalFormat("##,###,##0");

    String  imageName       = null;
    String  imageType       = null;
    String  imageAsBase64   = null;
    long    imageSize       = 0;

    try {
        if ( request.getParts() != null ) {
            for (Part filePart : request.getParts()) {
                if ( filePart.getSize() == 0 ) continue;

                imageName = filePart.getSubmittedFileName();
                imageType = imageName.replaceAll("(.*)\\.([^\\.]*)","$2");
                imageSize = filePart.getSize();

                byte[] fileBytes = new byte[(int)filePart.getSize()];
                try ( InputStream in = filePart.getInputStream(); ) {
                    in.read(fileBytes);
                    imageAsBase64 = new String(Base64.getEncoder().encode(fileBytes));
                }
            }
        }
    } catch (Exception ignore) {
    }
%><!DOCTYPE html>
<%@ page contentType="text/html;charset=windows-1252"%>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252"/>
        <title>Image Conversion: Base-64</title>
        <style>
        html,pre { font-family: "Arial Narrow"; }
        h1 { font-family: "Arial Narrow"; }
        h4 { margin: 15px 5px; margin-bottom:10px;  padding: 0px; font-family: "Arial Narrow"; }
        div { display: inline-block; }
        label { display: inline-block; padding: 0px; margin: 0px; min-width: 120px; text-align:left; font-weight: bold; }
        button { margin: 10px; padding: 5px 10px; border-radius: 5px; }
        </style>
        <script>
            // Return user to the default page by pressing ^[home] ([home] is key code: 36)
            document.addEventListener("keyup", (event) => {
                const keyName = event.key;
                const ctrlKeyPressed = event.ctrlKey;
                const altKeyPressed = event.altKey;
                if ( ctrlKeyPressed && altKeyPressed && keyName == "Home" ) {
                    var parser = location;
                    location = parser.origin + parser.pathname.replace(/(\/[^\/]*\/[^\/]*\/).*/,"$1default.jsp");
                    return;
                }
            }, false);
        </script>
    </head>
    <body>
    <h1> Convert Image to Base-64 Encoding </h1>


    <h4> Specify Image </h4>
    <div style="padding:20px;">
        <form action="<%= request.getRequestURI().replaceAll("(.*)/([^/]*)","$2") %>" method="post" enctype="multipart/form-data">
            <input type="file" name="imageToConvert"><br><br>
            <button> Convert Image File </button>
        </form>
    </div>


    <% if ( imageName != null ) { %>
        <div style="clear:both;height: 30px;"></div>
        <h4> Converted Image </h4>
        <pre>
        <label> Image Name: </label> <%= imageName %> 
        <label> Image Type: </label> <%= imageType %> 
        <label> Image Size: </label> <%= numberFormat.format(imageSize) %> 
        <label> Base-64 Size: </label> <%= numberFormat.format(imageAsBase64.length()) %> 
        <div style="clear:both;height: 30px;"></div>
        <label> Image Code: </label>
         &lt;img alt="Embedded Image" src="data:image/<%= imageType %>;base64,<%= imageAsBase64 %>"&gt;
        <div style="clear:both;height: 30px;"></div>
        <label> Image: </label>
        <img alt="Embedded Image" src="data:image/<%= imageType %>;base64,<%= imageAsBase64 %>">

        </pre>
    <% } %>

    </body>
</html>
