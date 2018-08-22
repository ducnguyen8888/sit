package act.log;

//import act.util.Sysutil;
import java.sql.*;
import java.text.*;
import java.util.*;
import java.util.logging.*;

public class SITLog extends Logs { 
    public SITLog() {
        super();
    }



    private static String logfileName = "SIT";

    protected static int file_size      = 10000000;
    protected static int file_rotation  = 20;


    private static long endOfMonth = 0;
    private static boolean isNewMonth() {
        return ((new java.util.Date()).getTime() > endOfMonth);
    }
    private static String getDatestamp() {
        Calendar c = new GregorianCalendar();
        return (c.get(Calendar.YEAR) - 2000) + (c.get(Calendar.MONTH) < 9 ? "0" : "") + (c.get(Calendar.MONTH) + 1);
    }

    private static Logger errorLog = null;

    private static Logger getLog() {
        if (errorLog == null || isNewMonth()) {
            endOfMonth = getEndOfMonth();
            if (errorLog != null)
                closeLog(errorLog);
            errorLog = getLog(logfileName, logfileRoot + logfileName + "." + getDatestamp() + ".%g.%u.log", file_size, file_rotation);
        }
        return errorLog;
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

    public static void info(String comment) {
        getLog().info(comment);
    }

    public static void warn(String comment) {
        getLog().warning(comment);
    }

    public static void warn(Exception e, String comment) {
        getLog().warning(comment + "\n" + e.toString());
    }

    public static void warn(Exception e) {
        getLog().warning(e.toString());
    }

    public static void severe(String comment) {
        getLog().severe(comment);
    }

    public static void severe(Exception e, String comment) {
        getLog().severe(comment + "\n" + e.toString());
    }

    public static void severe(Exception e) {
        getLog().severe(e.toString());
    }

    public static void error(String comment) {
        getLog().severe(comment);
    }

    public static void error(Exception e, String comment) {
        getLog().severe(comment + "\n" + e.toString());
    }

    public static void error(Exception e) {
        getLog().severe(e.toString());
    }
}