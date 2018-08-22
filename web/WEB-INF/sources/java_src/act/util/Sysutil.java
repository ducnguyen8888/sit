package act.util;

import java.io.*;
import java.sql.*;
import java.util.*;

public class Sysutil {
	public Sysutil() {
		super();
	}

	public static void main(String [] argv) {  
	    System.out.println(getWebRoot());
	    System.out.println(getLogRoot());
	    System.out.println(getConfigRoot());
	    System.out.println(getMidnight());
	    System.out.println(getEndOfMonth());
	}

	private static String webappDirectory = "webapp/";

	private static String webRoot = null;
	public static String getWebRoot() { return webRoot; }

	private static String logRoot = null;
	public static String getLogRoot() { return logRoot; }

	private static String configRoot = null;
	public static String getConfigRoot() { return configRoot; }

	private static Object refObj = new act.util.Sysutil();
	public static String getClassRoot() {
		String path = null;
		String resourcePath = "";
		try {
			//Object refObj = new act.util.Sysutil();
			resourcePath = refObj.getClass().getResource("/" + refObj.getClass().getName().replaceAll("\\.", "/") + ".class").getPath().replaceAll("%20", " ");
			path = resourcePath.substring(0, resourcePath.indexOf("/classes/"));
			return (new File(path)).getCanonicalPath() + File.separator;
		} catch (Exception e) {
		}
		return "";
	}

	static {
		String root = getClassRoot();
	    configRoot = root + webappDirectory + "configuration/";
	    logRoot = root + webappDirectory + "logs/";
		if ( root.indexOf("/WEB-INF/") > 0 )
			webRoot = root.substring(0,root.indexOf("/WEB-INF/")+1);
		else
			webRoot = root;
	}


	public static long getMidnight() {
		Calendar c = new GregorianCalendar();
		c.set(Calendar.HOUR_OF_DAY, 0);
		c.set(Calendar.MINUTE, 0);
		c.set(Calendar.SECOND, 0);
		c.set(Calendar.MILLISECOND, 0);
		c.add(Calendar.DATE, 1);
		return c.getTime().getTime();
	}

	public static long getEndOfMonth() { 
		Calendar c = new GregorianCalendar(); 
		c.set(Calendar.HOUR_OF_DAY, 0);
		c.set(Calendar.MINUTE, 0);
		c.set(Calendar.SECOND, 0);
		c.set(Calendar.MILLISECOND, 0);
	    c.set(Calendar.DATE, 1);
	    c.add(Calendar.MONTH, 1);
		return c.getTime().getTime();
	}


	public static final String getHost() {
		try {
			return java.net.InetAddress.getLocalHost().toString();
		} catch (Exception e) {
		}
		return "Unknown/0.0.0.0";
	}



	public static void extend(SQLException e, Object obj, String message) throws SQLException {
		extend(e, obj.getClass().getName(), message);
	}
	public static void extend(SQLException e, String activity, String message) throws SQLException {
		extend(e, activity+":"+message);
	}
	public static void extend(SQLException e, String message) throws SQLException {
		try {
			throw (Exception) e.getClass().getConstructor(new Class[]{(new String()).getClass()}).newInstance((Object[])(new String[]{message + ". " + e.getMessage()}));
		} catch (Exception oe) {
		}

		throw e; // Default to the original exception
	}

	public static SQLException extendMessage(SQLException e, Object obj, String message) {
		return extendMessage(e, obj.getClass().getName()+":"+message);
	}
	public static SQLException extendMessage(SQLException e, String activity, String message) {
		return extendMessage(e, activity+":"+message);
	}
	public static SQLException extendMessage(SQLException e, String message) {
		try {
			return (SQLException) e.getClass().getConstructor(new Class[]{(new String()).getClass()}).newInstance((Object[])(new String[]{message + ". " + e.getMessage()}));
		} catch (Exception oe) {
		}
		return e; // Default to the original exception
	}



	public static void extend(Exception e, Object obj, String message) throws Exception {
		extend(e, obj.getClass().getName()+":"+message);
	}
	public static void extend(Exception e, String activity, String message) throws Exception {
		extend(e, activity+":"+message);
	}
	public static void extend(Exception e, String message) throws Exception {
		try {
			throw (Exception) e.getClass().getConstructor(new Class[]{(new String()).getClass()}).newInstance((Object[])(new String[]{message + ". " + e.getMessage()}));
		} catch (Exception oe) {
		}
	    throw e; // Default to the original exception
	}

	public static Exception extendMessage(Exception e, Object obj, String message) throws Exception {
		return extendMessage(e, obj.getClass().getName()+":"+message);
	}
	public static Exception extendMessage(Exception e, String activity, String message) throws Exception {
		return extendMessage(e, activity+":"+message);
	}
	public static Exception extendMessage(Exception e, String message) throws Exception {
		try {
			return (Exception) e.getClass().getConstructor(new Class[]{(new String()).getClass()}).newInstance((Object[])(new String[]{message + ". " + e.getMessage()}));
		} catch (Exception oe) {
		}
		return e; // Default to the original exception
	}


	public static javax.servlet.ServletContext          getApplication(javax.servlet.jsp.PageContext pageContext) { return pageContext.getServletContext(); }
	public static javax.servlet.http.HttpSession        getSession(javax.servlet.jsp.PageContext pageContext) { return pageContext.getSession(); }
	public static javax.servlet.http.HttpServletRequest getRequest(javax.servlet.jsp.PageContext pageContext) { return (javax.servlet.http.HttpServletRequest) pageContext.getRequest(); }
	public static javax.servlet.ServletOutputStream     getOut(javax.servlet.jsp.PageContext pageContext) { try { return pageContext.getResponse().getOutputStream(); } catch (Exception e) {} return null; }

}
