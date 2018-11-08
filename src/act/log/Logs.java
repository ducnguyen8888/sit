package act.log;

import act.util.Sysutil;
import java.io.*;
import java.util.*;
import java.util.logging.*;
//import javax.xml.registry.infomodel.*;

public abstract class Logs {
	public Logs() { }

	public static void main (String [] argc) {
		System.out.println(Sysutil.getMidnight() );
	}



	protected static int file_size = 10000000;
	protected static int file_rotation = 20;
	protected static String logfileRoot = Sysutil.getLogRoot();
	public static void verifyLogfilePath(String logfilePath) {
		File log_root = new File(logfilePath.substring(0, logfilePath.lastIndexOf("/")));
		if (!log_root.exists())
			log_root.mkdirs();
	}


	static {
		verifyLogfilePath(logfileRoot);
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

	/**
	 ** List Available System Logfiles
	 **/
	public static String[] listLogs() {
		ArrayList array = new ArrayList();

		Enumeration logs = LogManager.getLogManager().getLoggerNames();
		while (logs.hasMoreElements())
			array.add(logs.nextElement());

		// These aren't anything we created, so we shouldn't do anything with them
		array.remove("oracle");
		array.remove("global");
		array.remove("javax.management.mbeanserver");
		array.remove("");
		return (String[])array.toArray();
	}


	/**
	 ** Logfile Handlers
	 **/
	public static boolean hasHandlers(Logger log) {
		Handler[] handlers = log.getHandlers();
		return (handlers != null && handlers.length > 0);
	}

	public static void addHandler(Logger log, String fullFilename, int size, int rotation) {
		try {
			java.util.logging.FileHandler fh = null;
			fh = new java.util.logging.FileHandler(fullFilename, size, rotation, true);
			fh.setFormatter(new java.util.logging.SimpleFormatter());
			log.addHandler(fh);
			log.setUseParentHandlers(false);
		} catch (Exception e) {
		}
	}


	/**
	 ** Close Logfile Handlers
	 **/
	public static synchronized void closeLog(String id) {
	    if ( id == null ) return;

		closeLog(java.util.logging.Logger.getLogger(id));
	}

	public static synchronized void closeLog(Logger log) {
		if ( log == null ) return;

		Handler[] handlers = log.getHandlers();
		if (handlers == null || handlers.length == 0)
			return;
		for (int i = 0; i < handlers.length; i++) {
			log.removeHandler(handlers[i]);
			handlers[i].flush();
			handlers[i].close();
		}
	}


	/**
	 ** Returns Logfile LOGGER
	 **/
	public static synchronized Logger getLog(String logId, String fullFilename, int size, int rotation) {
		if ( logId == null ) return null;

		Logger logger = java.util.logging.Logger.getLogger(logId);

		if ( ! hasHandlers(logger) ) {
			addHandler(logger, fullFilename, size, rotation);
		}

		return logger;
	}






	public static String createActivitySummary(javax.servlet.jsp.PageContext pageContext) {
		return createActivitySummary(pageContext,null);
	}
	public static String createActivitySummary(javax.servlet.jsp.PageContext pageContext, String description) {
		//javax.servlet.ServletContext          application = pageContext.getServletContext();
		//javax.servlet.http.HttpSession        session     = pageContext.getSession();
		javax.servlet.http.HttpServletRequest request     = (javax.servlet.http.HttpServletRequest)pageContext.getRequest();
		// javax.servlet.ServletOutputStream  out         = pageContext.getResponse().getOutputStream();

		StringBuffer summary = new StringBuffer();
		String val = null;

		try {
			// Date stamp for record sorting and readable version for viewing
			summary.append((new java.util.Date()).getTime());
			summary.append("\t");
			summary.append((new java.util.Date()).toString().substring(4, 19));
			summary.append("\t");

			// ////////
			// Page Requested
			val = request.getServletPath();
			val = val.substring(val.lastIndexOf("/"+1));
			summary.append(val);
			if (val.length() < 16) summary.append("                ".substring(val.length()));

		    summary.append("\t");
			if ( isDefined(description) ) {
				summary.append(description);
			}

			return summary.toString();
		} catch (Exception e) {
			return e.toString();
		} finally {
			summary.setLength(0);
			summary = null;
		}
	}




	// Need to add account/user who made the call
	public static String createRequestSummary(javax.servlet.jsp.PageContext pageContext) {
		return createRequestSummary(pageContext,null);
	}
	public static String createRequestSummary(javax.servlet.jsp.PageContext pageContext, String description) {
		javax.servlet.ServletContext          application = pageContext.getServletContext();
		javax.servlet.http.HttpSession        session     = pageContext.getSession();
		javax.servlet.http.HttpServletRequest request     = (javax.servlet.http.HttpServletRequest)pageContext.getRequest();
		// javax.servlet.ServletOutputStream  out         = pageContext.getResponse().getOutputStream();

		StringBuffer summary = new StringBuffer();


		String val = null;

		try {
			// Date stamp for record sorting and readable version for viewing
			summary.append((new java.util.Date()).getTime());
			summary.append("\t");
			summary.append((new java.util.Date()).toString().substring(4, 19));
			summary.append("\t");

			// ////////
			// IP based information
			summary.append(request.getRemoteAddr());
			summary.append("\t");

			// ////////
			// Session based information
			summary.append("             ".substring(("" + session.hashCode()).length()));
			summary.append(session.hashCode());
			summary.append("\t");


			// ////////
			// Page & GET Parameters
			summary.append(("GET".equals(request.getMethod()) ? "   GET" : "  POST"));
			summary.append("\t");
			val = request.getServletPath();
			val = val.substring(val.lastIndexOf("/"+1));
			summary.append(val);
			if (val.length() < 16) summary.append("                ".substring(val.length()));

		    summary.append("\t");
			if (isDefined(request.getQueryString())) {
				summary.append("?");
				summary.append(request.getQueryString());
			}

		    summary.append("\t");
		    if ( isDefined(description) ) {
		        summary.append(description);
		    }

			// Record POST data - only if not a payment or portfolio page
			if ("POST".equals(request.getMethod()) && request.getHeader("CONTENT-LENGTH") != null ) {
			    summary.append("\nPOST:\t");
				summary.append(getContentData(request));
			}


			return summary.toString();
		} catch (Exception e) {
			return e.toString();
		} finally {
			summary.setLength(0);
			summary = null;
		}
	}

	public static String getContentData(javax.servlet.http.HttpServletRequest request) {
		Hashtable excludeParams = new Hashtable();
		StringBuffer contentData = new StringBuffer();
		Map params = null;

		try {
			excludeParams.put("account_number", "");
			excludeParams.put("checking_account_number", "");
			excludeParams.put("confirm_account_number", "");
			excludeParams.put("cvc", "");
			if (isDefined(request.getQueryString())) {
				String[] p = request.getQueryString().split("&");
				for (int i = 0; i < p.length; i++) {
					excludeParams.put(p[i], "");
					p[i] = null;
				}
				p = null;
			}

			params = (java.util.Map)request.getParameterMap();
			String[] tkeys = (String[])params.keySet().toArray(new String[0]);
			if (tkeys.length > 0) {
				java.util.Arrays.sort(tkeys);
				for (int i = 0; i < tkeys.length; i++) {
					String[] paramValue = (String[])params.get(tkeys[i]);
					for (int j = 0; j < paramValue.length; j++) {
						String keyValuePair = tkeys[i] + "=" + paramValue[j];
						if (!excludeParams.containsKey(keyValuePair))
							contentData.append("&" + keyValuePair);
						else
							excludeParams.remove(keyValuePair);
						keyValuePair = null;
						paramValue[j] = null;
					}
					paramValue = null;
				}
			}
			tkeys = null;

			return (contentData.length() > 0 ? contentData.toString().substring(1) : "");
		} catch (Exception e) {
			return "Exception in getContentData(): " + e.toString();
		} finally {
			excludeParams.clear();
			excludeParams = null;
			contentData.setLength(0);
			contentData = null;
			params = null;
		}
	}

	public static boolean isDefined(String val) { return (val != null && val.length() > 0); }


}
