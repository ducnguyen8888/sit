<%@ page import="java.util.*,act.util.AppConfiguration" 
%><%!
String nvl(String value) { return (value == null ? "" : value.trim()); }
boolean notDefined(String value) { return value == null || value.length() == 0; }
%><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");


    // Not pleased with this setup. The properties/configuration file should be
    // loaded when user logs in and it should be made available as a session attribute.
    // Appears that client configuration files are used ONLY within the payment portion.

    // Sets our application configuration information
    String      clientId            = (String) session.getAttribute("client_id");
    String      dataSource          = "jdbc/sit";

    AppConfiguration configuration  = null;

    switch ( clientId )
    {
        case "2000"         :   configuration = new AppConfiguration(pageContext,"sitHarris");
                                break;
        case "7580"         :   configuration = new AppConfiguration(pageContext,"sitHarris");
                                break;
        case "79000000"     :   configuration = new AppConfiguration(pageContext,"sitFbc");
                                break;
        case "94000000"     :   
        case "94500000"     :   configuration = new AppConfiguration(pageContext,"sitElpaso");
                                break;
        case "98000000"     :   configuration = new AppConfiguration(pageContext,"sitGalveston");
                                break;
        default             :   configuration = new AppConfiguration(pageContext,"sitDallas");
                                break;
    }

    boolean     isTestTransaction   = "true".equals(configuration.getProperty("payment_isTest"));
    String      webDir              = configuration.getProperty("WEB_DIR");



    // Defined global settings for use on all control pages. This helps
    // to ensure that all of the pages are in-sync and using the same values.
    session.setAttribute("WEBPAY-Payment-testPayment",(isTestTransaction ? "true" : "false"));
    session.setAttribute("WEBPAY-Payment-clientId",clientId);
    session.setAttribute("WEBPAY-Payment-dataSource",dataSource);
    session.setAttribute("WEB_DIR",webDir);


%> { "status":  "OK",
     "config": {
                "isTest":           <%= isTestTransaction %>,
                "clientId":         "<%= clientId %>",
                "processor": {  "type": "vendor",
                                "id":     "Mail",
                                "name":   "Payment by Mail"
                            },
                "urls": {       "hBeat":           "control/sessionNotice.jsp",
                                "getPaymentData":  "control/getPaymentInformation.jsp",
                                "clearCart":       "control/clearCart.jsp",
                                "vendorPayment": {
                                        "PDS":      "control/processPaymentPDS.jsp",
                                        "JPMC":     "control/processPaymentJPMC.jsp",
                                        "Cadence":  "control/processPaymentCadence.jsp",
                                        "Mail":     "control/createReport.jsp"
                                }
                            }
            }
    }
