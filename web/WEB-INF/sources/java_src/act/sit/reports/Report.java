package act.sit.reports;

import act.util.Connect;

import act.util.URLResource;

import java.io.File;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.sql.Statement;

import java.text.SimpleDateFormat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import java.util.Date;

import javax.servlet.ServletResponse;

/**Provides the base structure used for Report execution.
 * <p>
 * All necessary functionality needed to execute a report is included in this
 * class with the exception of the report parameter string that will be unique
 * to each report. That class is expected to be implemented by each sub class
 * for the report it controls.
 * </p>
 * 
 * <p>The structure of the report generation is such that the report configuration
 * is chainable, that is it can be completely configured through a single statement. 
 * </p>
 * <pre> i.e.:  Report report = ImplementingReport.initialContext()
 *                                                .setAccount("7580", "00000172720000000")
 *                                                .create("jdbc/development");
 * </pre>
 * <p> The report name can be retrieved via the getFileName() method, or the URI can be 
 * retrived via the getReportURI() method.
 * </p>
 * 
 * 
 */
public abstract class Report {
    public Report() {
        super();
    }


    /** Retrieves and generates the report parameter string to submit to the report server
     * @returns the HTTP name/value parameter string to submit to the report server
     */
    public abstract String generateParameterString(Connection con) throws Exception;


    /** The complete URL, including parameters, in GET format useful for debugging */
    protected   String      debugURL                = null;
    /** Returns the complete URL, including parameters, in GET format the report generation call. Useful for debugging 
     * @return URL used to request report generation
     */
    public String getDebugURL() {
        return debugURL;
    }



    /** Report execution servlet request template URL to call when executing the report */
    protected   String      reportServerUrlFormat   = "http://%s/reports/rwservlet?";
    /** Report parameter format with pre-defined defaults, including handling report server name */
    protected   String      reportServerParamFormat = "SERVER=%s&USERID=sit_inq/texas1&DESTYPE=file&DESFORMAT=PDF&DESNAME=%s%s%s.pdf&%s";



    /** The expected response from the report server when the report was successfully executed */
    protected   String      successResponseFragment = "The report is successfully run";
    /** Identifies whether the report has been executed, does not indicate success/failure */
    protected   boolean     hasRun                  = false;
    /** Identifies whether the report was run and was successfully created */
    protected   boolean     wasSuccessful           = false;
    /** Report server response text generated during report execution request */
    protected   String      responseText            = null;
    /** The client processing exemption that occurred during executing, if any */
    protected   Exception   executionException      = null;

    /** The application server context path name used to retrieve the completed report */
    protected   String      reportContextPath       = "/dev60temp";
    /** The file system directory where the report server is to put the completed report */
    protected   String      outputDirectory         = "/usr2/webtemp/";
    /** The output filename prefix used when generating an output filename */
    protected   String      outputFilenamePrefix    = "wcs_";


    /** The output filename unique ID used when generating an output filename */
    public      String      uid                     = ""+(new java.util.Date()).getTime();


    /** The application server IP address used to contact the report server */
    public      String      appServerIPAddress      = null;

    /** The name of the report server */
    public      String      reportServerName        = null;

    /** The output filename of the completed report */
    public      String      outputFilename          = null;

    /** The full report server URL */
    public      String      reportServerUrl         = null;
    /** The parameter string sent to the report server to execute the report */
    public      String      reportParameters        = null;
    /** The object that handled submitting the HTTP request to the report server and extracting the response */
    public      URLResource urlResource             = null;

    public      String      reportUrl               = null;


    /** The client timezone offset from local time, used to determine the correct as-of-date */
    public      int         timeZoneOffset          = 0;
    /** The name of the report to be executed */
    public      String      reportName              = null;
    /** The as-of-date parameter value submitted to the report server */
    public      String      asOfDate                = null;
    /** The tax year parameter value submitted to the report server */
    public      String      taxYear                 = null;
    /** The over-65 parameter value submitted to the report server */
    public      String      over65Statement         = null;
    /** The TCS notes parameter value submitted to the report server */
    public      String      tcsNotesFlag            = "N";

    /** The account client ID parameter value submitted to the report server */
    public      String      clientId                = null;
    /** The account property tax account number (CAN) parameter value submitted to the report server */
    public      String      accountNumber           = null;
    /** The account property tax account owner number parameter value submitted to the report server */
    public      String      ownerNumber             = null;


    /** Sets the connection datasource used to retrieve report settings
     * @param datasource database datasource to retrieve settings from
     * @return this object, useful for chaining
     */
    public String getReportURI() {
        return reportContextPath + "/" + getFileName();
    }


    /** Sets the report name used to execute the report
     * @param reportName report name submitted to the report server
     * @return this object, useful for chaining
     */
    public Report setReportName(String reportName) {
        this.reportName = reportName;
        return this;
    }

    /** Sets a unique ID to use when creating the report output filename.
     * <p>This value is not used if the report output filename is set directly using setOutputFilename()</p>
     * @param uid a unique ID used as part of the output filename
     * @return this object, useful for chaining
     */
    public Report setUid(String uid) {
        this.uid = uid;
        return this;
    }

    /** Sets the report output filename that will be used by the report server to create the report
     * @param outputFilename name of the report file to create
     * @return this object, useful for chaining
     */
    public Report setOutputFilename(String outputFilename) {
        this.outputFilename = outputFilename;
        return this;
    }

    /** Sets the account to generate the report for
     * @param clientId client ID of the account
     * @param account property account number (CAN)
     * @return this object, useful for chaining
     */
    public Report setAccount(String clientId, String accountNumber) {
        this.clientId = clientId;
        this.accountNumber = accountNumber;
        this.ownerNumber = null;
        return this;
    }

    /** Sets the account to generate the report for
     * @param clientId client ID of the account
     * @param account property account number (CAN)
     * @param ownerno property owner number
     * @return this object, useful for chaining
     */
    public Report setAccount(String clientId, String accountNumber, String ownerNumber) {
        this.clientId = clientId;
        this.accountNumber = accountNumber;
        this.ownerNumber = ownerNumber;
        return this;
    }

    /** Sets the as-of-date timezone offset used in the report execution.
     * <p>This value is used only if the as-of-date is not set<p>
     * @param timezoneOffset
     * @return this object, useful for chaining
     */
    public Report setTimeZoneOffset(int timeZoneOffset) {
        this.timeZoneOffset = timeZoneOffset;
        return this;
    }

    /** Sets the as-of-date parameter used when executing the report
     * @param asOfDate report as-of-date value, usually YYYYMMDD
     * @return this object, useful for chaining
     */
    public Report setAsofDate(String asOfDate) {
        this.asOfDate = asOfDate;
        return this;
    }

    /** Sets the as-of-date parameter used when executing the report
     * @param asOfDate report as-of-date, converted to YYYYMMDD
     * @return this object, useful for chaining
     */
    public Report setAsofDate(Date asOfDate) {
        this.asOfDate = (new SimpleDateFormat("YYYYMMDD")).format(asOfDate);
        return this;
    }

    /** Sets the as-of-date parameter used when executing the report
     * @param asOfDate report as-of-date, converted to YYYYMMDD
     * @return this object, useful for chaining
     */
    public Report setAsofDate(LocalDate asOfDate) {
        this.asOfDate = asOfDate.format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        return this;
    }

    /** Sets the as-of-date parameter used when executing the report
     * @param asOfDate report as-of-date, converted to YYYYMMDD
     * @return this object, useful for chaining
     */
    public Report setAsofDate(LocalDateTime asOfDate) {
        this.asOfDate = asOfDate.format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        return this;
    }

    /** Sets the tax year parameter used when executing the report
     * @param taxYear year parameter used in the report generation
     * @return this object, useful for chaining
     */
    public Report setTaxYear(String taxYear) {
        this.taxYear = taxYear;
        return this;
    }

    /** Set the TCS notes parameter submitted with the report execution request
     * <p>This parameter is set only on the reports that use it. Setting this value
     * will not automatically include the TCS notes parameter.<p>
     * @param tcsNotesFlag should be 'N' or 'Y'
     * @return this object, useful for chaining
     */
    public Report setTCSNotes(String tcsNotesFlag) {
        this.tcsNotesFlag = tcsNotesFlag;
        return this;
    }


    /** Prepares and submits execution request to the report server
     * @param datasource database datasource name to pull settings from
     * @param user database user used to connect
     * @param password database password used to connect
     * @return this object, useful for chaining
     * @throws Exception if a connection or execution error occurs
     */
    public Report create(String datasource, String user, String password) throws Exception {
        try ( Connection con=Connect.open(datasource,user,password) ) {
            return create(con);
        }
    }

    /** Prepares and submits execution request to the report server
     * @param datasource database datasource name to pull settings from
     * @return this object, useful for chaining
     * @throws Exception if a connection or execution error occurs
     */
    public Report create(String datasource) throws Exception {
        try ( Connection con=Connect.open(datasource) ) {
            return create(con);
        }
    }

    /** Prepares and submits execution request to the report server
     * @param con database connection report settings are retrieved from
     * @return this object, useful for chaining
     * @throws Exception if a connection or execution error occurs
     */
    public Report create(Connection con) throws Exception {
        if ( hasRun ) throw new Exception ("Report has already been run");
        hasRun = true;

        try ( Statement statement=con.createStatement();
              ResultSet rs=statement.executeQuery(
                       "select "
                    +  "     act_utilities.get_codeset_value(null,'DESCRIPTION','WEB_APPSERVER','IP PORT') appServerIPAddress, "
                    +  "     act_utilities.get_codeset_value(null,'DESCRIPTION','WEB_REPORT_SERVER','NAME') reportServerName "
                    +  "  from dual"
                    ); 
              ){
            rs.next();

            appServerIPAddress  = rs.getString("appServerIPAddress");
            reportServerName    = rs.getString("reportServerName");

            outputFilename = nvl(outputFilename,String.format("%s%s.pdf",outputFilenamePrefix, uid));
            reportServerUrl = String.format(reportServerUrlFormat, appServerIPAddress);

            // Generate the report specific paramters
            reportParameters = this.generateParameterString(con);
            String fullReportServerParameters = String.format(reportServerParamFormat,
                                                                reportServerName,
                                                                outputDirectory, outputFilenamePrefix, uid,
                                                                reportParameters
                                                                );
            debugURL = String.format("%s%s",reportServerUrl,fullReportServerParameters);

            urlResource = URLResource.initialContext()
                                     .setServerUrl(reportServerUrl)
                                     .setPostData(fullReportServerParameters)
                                     .submit()
                                     ;


            wasSuccessful = (urlResource.response != null && urlResource.response.indexOf(successResponseFragment) > 0);
            if ( wasSuccessful ) {
                responseText = successResponseFragment;
            } else if ( urlResource.response != null ) {
                if ( urlResource.response.indexOf("<pre>") > 0 ) {
                    responseText = urlResource.response.substring(urlResource.response.indexOf("<pre>") + 5);
                    responseText = responseText.substring(0,responseText.indexOf("</pre>"));
                } else {
                    for ( int i=0; ! exists() && i < 10; i++ ) {
                        try { Thread.sleep(2000); } catch (Exception e) {}
                    }
                    wasSuccessful = exists();
                    responseText = (wasSuccessful ? successResponseFragment
                                                  : "Report ran but appears to not have been created within the expected timeframe"
                        );
                }
            }

            if ( ! wasSuccessful ) 
            {
                System.out.println(urlResource.getResponseHeaders());
                System.out.println(urlResource.toString());
                System.out.println("\n\n-------------------------------\n\n");
                System.out.println("Was Successful: " + wasSuccessful);
                System.out.println(responseText);
            }

            reportUrl = reportContextPath + "/" + outputFilename;
            //System.out.println(reportUrl);
        } catch (Exception exception) {
            executionException = exception;
            throw exception;
        }

        return this;
    }

    /** Identifies whether the report has been run or not.
     * @return true/false, true if the report was previously run
     */
    public boolean hasRun() {
        return hasRun;
    }

    /** Identifies whether the report execution was successful or not.
     * <p>This value will return false if called before the report has been run.
     * Any identifiable execution errors or reasons will be returned via the getException()
     * or the getResponseText() methods.</p>
     * <p>The report is considered successsfully run if the report server responds that it ran
     * successfully or, if the report server signifies that execution has been queued, the report
     * output file exists. Otherwise false will be returned.</p>
     * @return true/false, true if the report execution was successful
     */
    public boolean wasSuccessful() {
        return wasSuccessful;
    }
    public URLResource getURLResource() {
        return urlResource;
    }

    /** Returns the report execution response text. Any errors identified by the report server
     * should be included.
     * @return report execution response text
     */
    public String getResponseText() {
        return responseText;
    }

    /** Returns any processing exceptions encountered while executing the report. These are
     * client side execution errors and do not idnetify any report execution failures flagged
     * by the report server. For errors noted by the report server use getResponseText().
     * @return client processing exceptions
     */
    public Exception getException() {
        return executionException;
    }

    /** Returns the report output filename 
     * @return report output filename
     */
    public String getFileName() {
        return outputFilename;
    }

    /** Returns whether the report output file exists or not
     * @return true/false, true if the report output file exists, false otherwise.
     */
    public boolean exists() {
        return (new File(String.format("%s%s",outputDirectory,outputFilename))).exists();
    }


    //public ByteStream getReport() { //- Return report as byte stream
    //    return null;
    //}

    /**
     * @param response
     */
    public void returnReport(ServletResponse response) { // - Return report directly to user
        return;
    }

    /** Convenience method used during processing. If the values parameter is null then a
     * new empty String array is returned, otherwise the specified String array is returned.
     * @param values String array
     * @return a non-null String array
     */
    public String[] safe(String[] values) { 
        return (values == null ? new String[0] : values);
    }

    /** Convenience method. Returns first non-null value of the specified list. If all specified
     *  values are null then an emtpy String ("") is returned instead.
     * @param values one or more String values
     * @return
     */
    public String nvl(String... values) {
        for (String value : safe(values)) {
            if ( value != null ) return value;
        }
        return "";
    }

}
