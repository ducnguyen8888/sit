package act.log.epay;

import act.log.*;
import java.sql.*;
import java.text.*;
import java.util.*;
import java.util.logging.*;

public class ChaseLog extends Log { 
	public ChaseLog() {
		super();
	}


	/** Defines the error log file name */
	private static String logfileName = "epay/chase";

	/* Static initializer ran when class is first loaded */
	static {
		verifyLogfilePath(logfileDirectory + logfileName);
	}

	/** Defines the maximum file size for each log file */
	protected static int file_size      = 10000000;

	/** Defines how many log files to maintain in rotation before reusing */
	protected static int file_rotation  = 20;


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
			log = getLog(logfileName, logfileDirectory + logfileName + "." + getDatestamp() + ".%g.%u.log", file_size, file_rotation);
		}
		return log;
	}

	/** Logs an INFO level log entry
	 *  @param comment the log entry to log
	 */
	public static void info(String comment) {
		getLog().info(comment);
	}

	/** Logs a WARNING level log entry
	 *  @param comment the log entry to log
	 */
	public static void warn(String comment) {
		getLog().warning(comment);
	}

	/** Logs a WARNING level log entry
	 *  @param exception exception to log
	 *  @param comment the log entry to log
	 */
	public static void warn(Exception exception, String comment) {
		getLog().warning(comment + "\n" + exception.toString());
	}

	/** Logs a WARNING level log entry
	 *  @param exception exception to log
	 */
	public static void warn(Exception exception) {
		getLog().warning(exception.toString());
	}

	/** Logs a SEVERE level log entry
	 *  @param comment the log entry to log
	 */
	public static void severe(String comment) {
		getLog().severe(comment);
	}

	/** Logs a SEVERE level log entry
	 *  @param exception exception to log
	 *  @param comment the log entry to log
	 */
	public static void severe(Exception exception, String comment) {
		getLog().severe(comment + "\n" + exception.toString());
	}

	/** Logs a SEVERE level log entry
	 *  @param exception exception to log
	 */
	public static void severe(Exception exception) {
		getLog().severe(exception.toString());
	}

	/** Logs a SEVERE level log entry
	 *  @param comment the log entry to log
	 */
	public static void error(String comment) {
		getLog().severe(comment);
	}

	/** Logs a SEVERE level log entry
	 *  @param exception exception to log
	 *  @param comment the log entry to log
	 */
	public static void error(Exception exception, String comment) {
		getLog().severe(comment + "\n" + exception.toString());
	}

	/** Logs a SEVERE level log entry
	 *  @param exception exception to log
	 */
	public static void error(Exception exception) {
		getLog().severe(exception.toString());
	}
}
