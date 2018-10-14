<%@ page import="act.sit.reports.SITPayByMail" %><%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 10/12/2018
  Time: 11:45 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc"%>
<%
    boolean         wasPosted            = true;// "POST".equals(request.getMethod());
    String          tid                  = nvl( request.getParameter("tid"),"");
    Report          payByMail            = null;
    String          host                 = InetAddress.getLocalHost().getHostAddress()+"/"+InetAddress.getLocalHost().getHostName();

    if ( sitAccount.isValid()
            && wasPosted
            ){
        if ( !isDefined( tid ) ) {
            try {
                payByMail = SITPayByMail.initialContext(sitAccount.getClientId(), tid);
                payByMail.create(datasource);
                String paymentFormReponse = "{\"generatePaymentFormRequest\":\"success\","
                        + " \"data\" : { \"formExists\" : \"%s\","
                        + " \"response\":  \"%s\","
                        + " \"systemReport\":  \"%s\","
                        + " \"host\": \"%s\","
                        + " \"reportFileName\":  \"%s\","
                        + " \"retrievalURL\": \"%s\","
                        + " \"clientId\":  \"%s\","
                        + " \"tid\": \"%s\" }"
                        + " } ";

                out.println(String.format(paymentFormReponse, payByMail.wasSuccessful(),payByMail.getResponseText(), "payment_form",host, payByMail.getFileName(), payByMail.getReportURI(), sitAccount.getClientId(), tid));



            } catch (Exception e) {
                String paymentFormReponse = "{\"generatePaymentFormRequest\":\"success\","
                        + " \"data\" : { \"formExists\" : \"%s\","
                        + " \"response\": \"%s\","
                        + " \"failureReason\": \"%s\","
                        + " \"systemReport\":  \"%s\","
                        + " \"host\": \"%s\","
                        + " \"reportFileName\":  \"%s\","
                        + " \"retrievalURL\": \"%s\","
                        + " \"clientId\":  \"%s\","
                        + " \"tid\":  \"%s\" }"
                        + " } ";
                out.println(String.format(paymentFormReponse, payByMail.wasSuccessful(), payByMail.getResponseText(), e.getMessage().toString(), "payment_form", host, payByMail.getFileName(), payByMail.getReportURI(), sitAccount.getClientId(), tid));
            }
        } else {
            out.println(String.format("{\"generatePaymentFormRequest\":\"failure\",\"detail\":\"Tid is not provided\"}"));
        }
    } else {
        out.println(String.format("{\"generatePaymentFormRequest\":\"failure\",\"detail\":\"Request can not be processed\"}"));
    }

%>
