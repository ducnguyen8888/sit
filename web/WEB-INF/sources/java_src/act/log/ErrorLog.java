package act.log;

import java.sql.*;
import java.util.*;
import java.util.logging.*;


public class ErrorLog extends Log {
	public ErrorLog() {
		super();
	}

	public static void main(String[] args) {
		info("sub class test");
		warn(new SQLException("Wrong column"),"Running Query");
	}


	/** Defines the error log filename */
	private static final String logfileName = "error";


	/** Defines the maximum file size for each log file */
	protected static int file_size = 10000000;

	/** Defines how many log files to maintain in rotation before reusing */
	protected static int file_rotation = 20;


	/** Tracks the Date time of the end of the month */
	private static long endOfMonth = 0;

	/** Returns whether the current date/time is after the last tracked end-of-month.
	 *  @returns true if the current date/time is after the end of month, false otherwise
	 */
	private static boolean isNewMonth() { return ((new java.util.Date()).getTime() > endOfMonth); }

	/** Returns a YYMM date stamp used as part of the log filename
	 *  @returns current Year and Month in YYMM format, i.e. 1601, which is January, 2016
	 */
	private static String getDatestamp() {
		Calendar c = new GregorianCalendar();
		return (c.get(Calendar.YEAR) -2000)
				+ (c.get(Calendar.MONTH) < 9 ? "0" : "") + (c.get(Calendar.MONTH)+1);
	}

	/** Tracks the current log for quick access */
	private static Logger log = null;

	/** Returns the current logger.
	 *  Returns the current logger and manages creation of new logs when the date naming
	 *  needs to change.
	 *  @returns current logger
	 */
	private static Logger getLog() {
		if ( log == null || isNewMonth() ) {
			endOfMonth = getEndOfMonth();
			if ( log != null ) closeLog(log);
			log = getLog(logfileName, logfileDirectory + logfileName + "." + getDatestamp() + ".%g.%u.log",file_size,file_rotation);
		}
		return log;
	}


	/** Logs a INFO level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 */
	public static void info(javax.servlet.jsp.PageContext pageContext) {
	    getLog().info(createRequestSummary(pageContext));
	}

	/** Logs an INFO level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param exception exception to log as detail information
	 */
	public static void info(javax.servlet.jsp.PageContext pageContext, Throwable exception) {
		getLog().info(createRequestSummary(pageContext) + "\n" + exception.toString());
	}

	/** Logs a INFO level log entry along with the additional note in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param note a descriptive note added to the log entry
	 */
	public static void info(javax.servlet.jsp.PageContext pageContext, String note) {
		getLog().info(createRequestSummary(pageContext) + "\n" + note);
	}

	/** Logs an INFO level log entry in the log file.
	 *  @param message the log entry to log
	 */
	public static void info(String note) {
		getLog().info(note);
	}

	/** Logs an INFO level log entry in the log file.
	 *  @param exception exception to log as detail information
	 *  @param message the log entry to log
	 */
	public static void info(Throwable exception, String note) {
		getLog().info(note + "\n" + exception.toString());
	}

	/** Logs a WARNING level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 */
	public static void warn(javax.servlet.jsp.PageContext pageContext) {
		getLog().warning(createRequestSummary(pageContext));
	}

	/** Logs a WARNING level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param exception exception to log as detail information
	 */
	public static void warn(javax.servlet.jsp.PageContext pageContext, Throwable exception) {
		getLog().warning(createRequestSummary(pageContext) + "\n" + exception.toString());
	}

	/** Logs a WARNING level log entry along with the additional note in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param note a descriptive note added to the log entry
	 */
	public static void warn(javax.servlet.jsp.PageContext pageContext, String note) {
		getLog().warning(createRequestSummary(pageContext) + "\n" + note);
	}

	/** Logs a WARNING level log entry in the log file.
	 *  @param message the log entry to log
	 */
	public static void warn(String note) {
		getLog().warning(note);
	}

	/** Logs a WARNING level log entry in the log file.
	 *  @param exception exception to log as detail information
	 *  @param message the log entry to log
	 */
	public static void warn(Throwable exception, String note) {
		getLog().warning(note + "\n" + exception.toString());
	}


	/** Logs a SEVERE level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 */
	public static void severe(javax.servlet.jsp.PageContext pageContext) {
		getLog().severe(createRequestSummary(pageContext));
	}

	/** Logs a SEVERE level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param exception exception to log as detail information
	 */
	public static void severe(javax.servlet.jsp.PageContext pageContext, Throwable exception) {
		getLog().severe(createRequestSummary(pageContext) + "\n" + exception.toString());
	}

	/** Logs a SEVERE level log entry along with the additional note in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param note a descriptive note added to the log entry
	 */
	public static void severe(javax.servlet.jsp.PageContext pageContext, String note) {
		getLog().severe(createRequestSummary(pageContext) + "\n" + note);
	}

	/** Logs a SEVERE level log entry in the log file.
	 *  @param message the log entry to log
	 */
	public static void severe(String note) {
		getLog().severe(note);
	} 

	/** Logs a SEVERE level log entry in the log file.
	 *  @param exception exception to log as detail information
	 *  @param message the log entry to log
	 */
	public static void severe(Throwable exception, String note) {
		getLog().severe(note + "\n" + exception.toString());
	}


	/** Logs a SEVERE level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 */
	public static void error(javax.servlet.jsp.PageContext pageContext) {
		getLog().severe(createRequestSummary(pageContext));
	}

	/** Logs a SEVERE level log entry in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param exception exception to log as detail information
	 */
	public static void error(javax.servlet.jsp.PageContext pageContext, Throwable exception) {
		getLog().severe(createRequestSummary(pageContext) + "\n" + exception.toString());
	}

	/** Logs a SEVERE level log entry along with the additional note in the log file with information about the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param note a descriptive note added to the log entry
	 */
	public static void error(javax.servlet.jsp.PageContext pageContext, String note) {
		getLog().severe(createRequestSummary(pageContext) + "\n" + note);
	}

	/** Logs a SEVERE level log entry in the log file.
	 *  @param message the log entry to log
	 */
	public static void error(String note) {
		getLog().severe(note);
	}

	/** Logs a SEVERE level log entry in the log file.
	 *  @param exception exception to log as detail information
	 *  @param message the log entry to log
	 */
	public static void error(Throwable exception, String note) {
		getLog().severe(note + "\n" + exception.toString());
	}


	/** Creates a summary log entry for the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @returns a summary log entry
	 */
	public static String createRequestSummary(javax.servlet.jsp.PageContext pageContext) {
		return createRequestSummary(pageContext, null);
	}

	/** Creates a summary log entry for the JSP page request.
	 *  @param pageContext the JSP page context object
	 *  @param description additional information to add to the log entry
	 *  @returns a summary log entry
	 */
	public static String createRequestSummary(javax.servlet.jsp.PageContext pageContext, String description) {
		javax.servlet.ServletContext          application = pageContext.getServletContext();
		javax.servlet.http.HttpSession        session     = pageContext.getSession();
		javax.servlet.http.HttpServletRequest request     = (javax.servlet.http.HttpServletRequest)pageContext.getRequest();
		// javax.servlet.ServletOutputStream  out         = pageContext.getResponse().getOutputStream();

		StringBuffer summary = new StringBuffer();


		String val = null;
		int idx = 0;

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
			idx = val.lastIndexOf("/")+1;
			val = val.substring(0, idx) + "\t" + val.substring(idx);
			summary.append(val);

			summary.append("\t");
			if ( isDefined(description) ) {
				summary.append(description);
			}

			// Record GET data - only if not a payment or portfolio page
			if (isDefined(request.getQueryString())) {
				summary.append("\nGET:\t");
				summary.append("?");
				summary.append(request.getQueryString());
			}

			// Record POST data - only if not a payment or portfolio page
			if ("POST".equals(request.getMethod()) && request.getHeader("CONTENT-LENGTH") != null ) {
				summary.append("\nPOST:\t");
				summary.append(getContentData(request));
			}

			summary.append("\nREF:\t");
			summary.append( (request.getHeader("REFERER") == null ? "{undefined}" : request.getHeader("REFERER")) );

			return summary.toString();
		} catch (Exception e) {
			return summary.toString() + "\n" + e.toString();
		} finally {
			summary.setLength(0);
			summary = null;
		}
	}

}
