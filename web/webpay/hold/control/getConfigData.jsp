<%@ page import="java.util.*,act.util.AppConfiguration" 
%><%!
String nvl(String value) { return (value == null ? "" : value.trim()); }
boolean notDefined(String value) { return value == null || value.length() == 0; }
%><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");


    // Sets our application configuration information

    AppConfiguration configuration  = new AppConfiguration(pageContext,"sitDallas");

    boolean     isTestTransaction   = "true".equals(configuration.getProperty("payment_isTest"));

    String      clientId            = configuration.clientId;
    String      dataSource          = configuration.dataSource;
    String      clientRoot          = "https://actweb.acttax.com/act_webtest/harlingen/";
    String      accountSearchUrl    = "https://actweb.acttax.com/act_webtest/harlingen/index.jsp";
    String      accountDetailUrl    = "https://actweb.acttax.com/act_webtest/harlingen/showDetail2.jsp?can=";



/*
    //  Page should not be requested directly
    if ( notDefined(request.getHeader("REFERER")) ) {
        for (Enumeration<String> e = session.getAttributeNames(); e.hasMoreElements();) {
            String name = (String) e.nextElement();
            if ( name.startsWith("WEBPAY-") )
                session.removeAttribute(name);
        }
        response.setStatus(404);
        return;
    }
*/

    // Defined global settings for use on all control pages. This helps
    // to ensure that all of the pages are in-sync and using the same values.
    session.setAttribute("WEBPAY-Payment-testPayment",(isTestTransaction ? "true" : "false"));
    session.setAttribute("WEBPAY-Payment-clientId",clientId);
    session.setAttribute("WEBPAY-Payment-dataSource",dataSource);
    session.setAttribute("WEBPAY-Payment-url-clientUrl",clientRoot);
    session.setAttribute("WEBPAY-Payment-url-accountSearch",accountSearchUrl);

%> { "status":  "OK",
     "config": {
                "isTest":           <%= isTestTransaction %>,
                "clientId":         "<%= clientId %>",
                "processor": {  "type": "vendor",
                                "id":     "JPMC",
                                "name":   "JP Morgan Chase",
                                "params": { "biller": "<%= configuration.getProperty("chaseBiller") %>",
                                            "billerGroup": "<%= configuration.getProperty("chaseBillerGroup") %>"
                                            },
                                "rates": {  "echeck":     { "amount": "0",  "minimum": "0" },
                                            "creditcard": { "rate":   "0.0225", "minimum": "0.01" },
                                            "debitcard": { "amount":   "3.50", "minimum": "0" }
                                        }
                            },
                "urls": {       "hBeat":           "control/sessionNotice.jsp",
                                "getPaymentData":  "control/getPaymentInformation.jsp",
                                "clearCart":       "control/clearCart.jsp",
                                "vendorPayment": {
                                        "PDS":     "control/processPaymentPDS.jsp",
                                        "JPMC":    "control/processPaymentJPMC.jsp"
                                }
                            }
            }
    }
