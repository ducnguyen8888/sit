<%@ include file="../_configuration.inc" %><%
	response.addHeader("Pragma" , "No-cache") ;
	response.addHeader("Cache-Control", "no-cache") ;
	response.addDateHeader("Expires", 0); 
out.print("can is " + request.getParameter("can"));
	String contentType = request.getContentType();
	boolean itWorked = false;
	if ((contentType != null) && (contentType.indexOf("multipart/form-data") >= 0)) {
		long millis = System.currentTimeMillis() / 1000;
		String addl_file_name = "SIT_ADDL_" + millis + ".pdf";
		InputStream inputStream = null;
		OutputStream outputStream = null;
		// read this file into InputStream
		inputStream = new DataInputStream(request.getInputStream());
		// write the inputStream to a FileOutputStream
		outputStream = new FileOutputStream(new File(tempDirectory + addl_file_name));//tempDirectory = "/usr2/webtemp/";
		int read = 0;
		byte[] bytes = new byte[1024];
		while ((read = inputStream.read(bytes)) != -1) {
			outputStream.write(bytes, 0, read);
		}
		outputStream.flush();
		outputStream.close();
		Runtime.getRuntime().exec( "/usr/bin/chmod 666 " + tempDirectory + addl_file_name );
		itWorked = true;
	} else {
		itWorked = false;
	}
%>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Additional Upload</title>
</head>
<body>
<% if (itWorked) { %>

<div style="margin-left:auto; margin-right: auto; width: 500px; font-family: arial; text-align: center;">
	Your file has been uploaded.<br>Click the back button to continue form finalization.
	<form method="post" action="<%= request.getHeader("referer") %>">
    <input type="hidden" name="can" id="can" value="<%= request.getParameter("can") %>">
    <input type="hidden" name="name" id="name" value="<%= request.getParameter("name") %>">
    <input type="hidden" name="year" id="year" value="<%= request.getParameter("year") %>">
    <input type="hidden" name="month" id="month" value="<%= request.getParameter("month") %>">
    <input type="hidden" name="category" id="category" value="<%= request.getParameter("category") %>">
    <input type="hidden" name="bizStart" id="bizStart" value="<%= request.getParameter("bizStart") %>">
    <button type="submit">Back to form</button>
	</form>
</div>

<% } else { %>
it didn't work


<% } %>
</body>
</html>