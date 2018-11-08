package act.log;

import java.io.File;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Enumeration;
import java.util.GregorianCalendar;
import java.util.Hashtable;
import java.util.Map;
import java.util.logging.Handler;
import java.util.logging.LogManager;
import java.util.logging.Logger;


public class Log {
	public Log() { }


	/** Defines the root location of the log files relative to the application server root */
	public static final String logsSubdirectory = "webapp/logs/";


	/** Defines the maximum file size for each log file */
	protected static int file_size = 10000000;

	/** Defines how many log files to maintain in rotation before reusing */
	protected static int file_rotation = 20;

	/** Returns the file system path to the log file root directory.
	 *  @returns the absolute file path to the log file root directory
	 */
	public static String getLogDirectory() {
		String logpath = null;
		try {
			// It appears that the Reference object must be from the user classes, otherwise
			// the class loader won't find our class file under Oracle application server.
			String path = (new Log()).getClass().getResource("/act/log/Log.class").getPath().replaceAll("%20"," ");
			path = path.substring(0,path.indexOf("/classes/")+1) + logsSubdirectory;
			logpath = (new File(path)).getCanonicalPath() + File.separator;
		} catch (Exception e) {
		}
		return logpath;
	}

	/** Verifies that the file system directory path exists.
	 *  If the specified directory doesn't exist it is created. If
	 *  the path is a directory it must end with a trailing slash.
	 *  If the path doesn't have a trailing slash it is assumed to be
	 *  a file name and only the directory portion is verified.
	 *  @param path file system directory path to verify
	 */
	public static void verifyLogfilePath(String path) {
		if ( path == null ) return;

		// Normalize our path string (DOS vs Unix) and make sure we have
		// only the directory portion.
		path = path.replaceAll("\\\\","/"); // Convert to Unix standard

		// If the path is a filename we'll extract the directory portion
		if ( path.indexOf("/") > 0 && ! path.endsWith("/") ) {
			path = path.substring(0,path.lastIndexOf("/"));
		}

		// Verify that the directory exists, otherwise create it
		File directory = new File(path);
	    if ( ! directory.exists() ) directory.mkdirs();
	}


	/** The file system directory location the log files are created in */
	protected static final String logfileDirectory = getLogDirectory();


	/* Static initializer ran when class is first loaded */
	static {
		verifyLogfilePath(logfileDirectory);
	}


	/** List all registered log file handlers available.
	 *  Some default log file handlers are removed from the return list.
	 *  The following handlers are not included:
	 *  <li> oracle </li>
	 *  <li> global </li>
	 *  <li> javax.management.mbeanserver </li>
	 *  @returns an array registered log file handlers
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


	/** Returns whether a particular log file logger has any registered handlers.
	 *  @param log log file logger to check for registered handlers
	 *  @returns true if there are any registered handlers, false otherwise
	 */
	public static boolean hasHandlers(Logger log) {
		Handler[] handlers = log.getHandlers();
		return (handlers != null && handlers.length > 0);
	}

	/** Adds a log file handler to a log file logger.
	 *  @param log log file logger to add the handler to
	 *  @param fullFilename the full system path file name of the log file
	 *  @param size the maximum size of each individual log file
	 *  @param rotation the number of files to maintain in rotation before reusing a file name
	 */
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


	/** Closes a log file logger by closing all registered handers.
	 *  @param id the id of the log file to close
	 **/
	public static synchronized void closeLog(String id) {
	    if ( id == null ) return;

		closeLog(java.util.logging.Logger.getLogger(id));
	}

	/** Closes a log file logger by closing all registered handers.
	 *  @param log the log file logger to close
	 **/
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


	/** Returns a log file logger by id.
	 *  If no handlers are registered to the logger a new handler is registered
	 *  prior to returning the logger.
	 *  @param id the registered id of the logger to return
	 *  @param fullFilename the full file system path and file name of the log file
	 *                      to use when creating a handler for the logger. Used only
	 *                      if a handler isn't already registered for the logger.
	 *  @param size         the maximum log file size, used only if a handler doesn't already exist
	 *  @param rotation     the number of physical log files to rotate, used only if a handler doesn't already exist
	 *  @returns logger with the specified id
	 **/
	public static synchronized Logger getLog(String id, String fullFilename, int size, int rotation) {
		if ( id == null ) return null;

		Logger logger = java.util.logging.Logger.getLogger(id);

		if ( ! hasHandlers(logger) ) {
			addHandler(logger, fullFilename, size, rotation);
		}

		return logger;
	}




	/** Returns a basic JSP page request activity summary log entry.
	 *  @param pageContext JSP page pageContext
	 *  @return basic log entry detailing the JSP page request
	 */
	public static String createActivitySummary(javax.servlet.jsp.PageContext pageContext) {
		return createActivitySummary(pageContext,null);
	}
	/** Returns a basic JSP page request activity summary log entry.
	 *  @param pageContext JSP page pageContext
	 *  @param description additional information to add to the log entry
	 *  @return basic log entry detailing the JSP page request
	 */
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




	/** Returns a more detailed JSP page request activity summary log entry.
	 *  @param pageContext JSP page pageContext
	 *  @return log entry detailing the JSP page request
	 */
	public static String createRequestSummary(javax.servlet.jsp.PageContext pageContext) {
		return createRequestSummary(pageContext,null);
	}
	/** Returns a more detailed JSP page request activity summary log entry.
	 *  @param pageContext JSP page pageContext
	 *  @param description additional information to add to the log entry
	 *  @return log entry detailing the JSP page request
	 */
	public static String createRequestSummary(javax.servlet.jsp.PageContext pageContext, String description) {
		return createRequestSummary((javax.servlet.http.HttpServletRequest)pageContext.getRequest(),description);
	}
	/** Returns a more detailed JSP page request activity summary log entry.
	 *  @param request JSP page request
	 *  @return log entry detailing the JSP page request
	 */
	public static String createRequestSummary(javax.servlet.http.HttpServletRequest request) {
		return createRequestSummary(request,null);
	}
	/** Returns a more detailed JSP page request activity summary log entry.
	 *  @param request JSP page request
	 *  @param description additional information to add to the log entry
	 *  @return log entry detailing the JSP page request
	 */
	public static String createRequestSummary(javax.servlet.http.HttpServletRequest request, String description) {
		//javax.servlet.ServletContext          application = pageContext.getServletContext();
		javax.servlet.http.HttpSession        session     = request.getSession();
		//javax.servlet.http.HttpServletRequest request     = (javax.servlet.http.HttpServletRequest)pageContext.getRequest();
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

	/** Returns the request parameters as a HTTP key/value pair.
	 *  Returns the parameters in the same key/value format as used with HTTP GET/POST requests.
	 *  @param request the JSP HTTP request object to retrieve the parameter key/value information from
	 *  @returns the parameters in the HTTP GET/POST format, i.e. key1=value1&key2=value2&...
	 */
	public static String getContentData(javax.servlet.http.HttpServletRequest request) {
		Hashtable excludeParams = new Hashtable();
		StringBuffer contentData = new StringBuffer();
		Map params = null;

		try {
			excludeParams.put("account_number", "");
			excludeParams.put("checking_account_number", "");
			excludeParams.put("confirm_account_number", "");
			excludeParams.put("cvc", "");
			excludeParams.put("cvv", "");
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


	/** Returns the date time of midnight of the current date.
	 *  The date time returned is the Java Date.getTime() value.
	 *  @returns the Date.getTime() value of midnight of the current date.
	 */
	public static long getMidnight() {
		Calendar c = new GregorianCalendar();
		c.set(Calendar.HOUR_OF_DAY, 0);
		c.set(Calendar.MINUTE, 0);
		c.set(Calendar.SECOND, 0);
		c.set(Calendar.MILLISECOND, 0);
		c.add(Calendar.DATE, 1);
		return c.getTime().getTime();
	}

	/** Returns the date time of midnight of the last day of the current month.
	 *  The date time returned is the Java Date.getTime() value.
	 *  @returns the Date.getTime() value of midnight of the last day of the current month.
	 */
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


	/** Returns the name/IP of the host server.
	 *  @returns name/IP of the host server
	 */
	public static final String getHost() {
		try {
			return java.net.InetAddress.getLocalHost().toString();
		} catch (Exception e) {
		}
		return "Unknown/0.0.0.0";
	}

	/** Returns whether the string value is defined or not.
	 *  The value is determined to be defined if it is not null and has a length greater than 0.
	 *  @param val String value to determine whether it is defined or not
	 *  @returns true if value is not null and has a length greater than 0, false otherwise
	 */
	public static boolean isDefined(String val) { return (val != null && val.length() > 0); }

	/** Returns the JSP application object from the pageContext.
	 *  @param the JSP pageContext
	 *  @returns the JSP application object
	 */
	public static javax.servlet.ServletContext getApplication(javax.servlet.jsp.PageContext pageContext) {
		return (javax.servlet.ServletContext) (pageContext == null ? null : pageContext.getServletContext());
	}
	/** Returns the JSP session object from the pageContext.
	 *  @param the JSP pageContext
	 *  @returns the JSP session object
	 */
	public static javax.servlet.http.HttpSession getSession(javax.servlet.jsp.PageContext pageContext) {
		return (javax.servlet.http.HttpSession) (pageContext == null ? null : pageContext.getSession());
	}
	/** Returns the JSP session object from the JSP request object.
	 *  @param the JSP request
	 *  @returns the JSP session object
	 */
	public static javax.servlet.http.HttpSession getSession(javax.servlet.http.HttpServletRequest request) {
		return (javax.servlet.http.HttpSession) (request == null ? null : request.getSession());
	}
	/** Returns the JSP request object from the pageContext.
	 *  @param the JSP pageContext
	 *  @returns the JSP request object
	 */
	public static javax.servlet.http.HttpServletRequest getRequest(javax.servlet.jsp.PageContext pageContext) {
		return (javax.servlet.http.HttpServletRequest) (pageContext == null ? null : pageContext.getRequest());
	}
	/** Returns the JSP response object from the pageContext.
	 *  @param the JSP pageContext
	 *  @returns the JSP response object
	 */
	public static javax.servlet.ServletResponse getResponse(javax.servlet.jsp.PageContext pageContext) {
		return (javax.servlet.ServletResponse) (pageContext == null ? null : pageContext.getResponse());
	}
	/** Returns the JSP response output stream object from the pageContext.
	 *  @param the JSP pageContext
	 *  @returns the JSP response output stream object
	 */
	public static javax.servlet.ServletOutputStream getOutputStream(javax.servlet.jsp.PageContext pageContext) throws Exception {
		return (javax.servlet.ServletOutputStream) (pageContext == null ? null : pageContext.getResponse().getOutputStream());
	}

	//javax.servlet.ServletContext          application = pageContext.getServletContext();
	//javax.servlet.http.HttpSession        session     = pageContext.getSession();
	//javax.servlet.http.HttpSession        session     = request.getSession();
	//javax.servlet.http.HttpServletRequest request     = (javax.servlet.http.HttpServletRequest)pageContext.getRequest();
	//javax.servlet.ServletResponse         response    = pageContext.getResponse();
	//javax.servlet.ServletOutputStream     out         = pageContext.getResponse().getOutputStream();

}
