<%@ page import="act.sit.*" %><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");

    Dealerships dealerships = (Dealerships) session.getAttribute("ds");
    Payments    payments    = (Payments) session.getAttribute("payments");
    String      clientId    = (String) session.getAttribute("WEBPAY-Payment-clientId");

    if ( dealerships == null ) {
        %>Dealerships not found<%
        return;
    }
    if ( payments == null ) {
        %>Payments not found<%
        return;
    }

    String cartJson = payments.getPayments(dealerships).trim().replaceFirst("\\{","");
    %>
{ "status":"OK",
    "payment": {
            "isTest":false,
            "CID":"<%= clientId %>",
            "RID":"749fe9e1c0c2a790e5c959b12034",
            "status":"Ready",
            "options":{"require":{"phone":true,"email":true},"enableAll":false},
            "method": { "type":"vendor",
                        "displayName": "Cadence Bank",
                        "rates": [
                                {  "name": "eCheck",       "amount": "0.00",
                                            "xnote": "Maximum E-Check payment (incl fees): $999,999.00" },
                                {  "name": "credit/debit card",   "rate":   "0.0235", "minimum": "1.00",  "maximum": "", 
                                            "xnote": "Maximum Credit Card payment (incl fees): $99,999.00" },
                                {  "name": "Visa consumer debit card",    "amount": "3.95", 
                                            "xnote": "Maximum Visa Debit Card payment (incl fees): $99,999.00" }
                                ]
                    },
            "contact":{
                    "country":"",
                    "name":"",
                    "street":"",
                    "city":"",
                    "state":"",
                    "zipcode":"",
                    "phone":"",
                    "email":"",
                    "vemail":""
                },
            <%= cartJson %>
    }
<%--
The expected JSON payment data format, returned by act.sit.Payment, is as follows:

{
  "name": "John Doe",
  "username": "John Doe",
  "client": "79000000",
  "client_id": "79000000",
  "dealers": [
  {
    "can" : "8888",
    "nameline1" : "DAWNS CARS AND TRUCKS",
    "nameline2" : "100 MAIN STREET",
    "nameline3" : "null",
    "nameline4" : "null",
    "city" : "CITY",
    "state" : "TX",
    "zipcode" : "78070",
    "payment" : [
      {
        "description" : "November 2015",
        "month" : "11",
        "year" : "2015",
        "reportSeq" : "1",
        "amountDue" : "0.00",
        "amountPending" : "0.0",
        "paymentAmount" : "0.00",
        "minPayment" : "0.0",
        "maxPayment" : "0.00"
      }
    ]
  }]
}

--%>
