<%@ page import="java.util.*,java.io.*" 
%><%--
--%><%!

	Object refObj = new act.util.EMail();
	String resourcePath = refObj.getClass()
						 .getResource("/" + refObj.getClass().getName().replaceAll("\\.", "/") + ".class")
						 .getPath().replaceAll("%20", " ");
	String rootPath = resourcePath.substring(0,resourcePath.indexOf("/WEB-INF/"));

	String weblogsRoot = rootPath + "/WEB-INF/_weblogs/";
	String logfileRoot = rootPath + "/_logfiles/";
	String logsRoot = rootPath + "/Logs/";
	String sitRoot = rootPath + "/webbapp/logs/sit/";


	public void resetFilePermissions(String file) {
		if ( file == null || file.length() == 0 ) return;

		try {
			String command = "/usr/bin/chmod 777 " + file;
			Process child = Runtime.getRuntime().exec(command);
		} catch (Exception e) {
		}
	}

	public void resetDirectoryPermissions(String filepath) {
		if ( filepath == null || filepath.length() == 0 ) return;

		File [] files = (new File(filepath)).listFiles();
		if ( files == null || files.length == 0 ) return;
		for ( int i=0; i < files.length;i++ ) {
			resetFilePermissions(files[i].getAbsolutePath());
		}
	}

%><%
	response.addHeader("Pragma", "No-cache");
	response.addHeader("Cache-Control", "no-cache");
	response.addDateHeader("Expires", 0);


	%><h2> Logfile Permissions Reset </h2><%

	%><li> <%= weblogsRoot %> </li><%
	resetDirectoryPermissions(weblogsRoot);

	%><li> <%= logfileRoot %> </li><%
	resetDirectoryPermissions(logfileRoot);

	%><li> <%= logsRoot %> </li><%
	resetDirectoryPermissions(logsRoot);
%><li> <%= sitRoot %> </li><%
	resetDirectoryPermissions(sitRoot);
%>
