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
            "methods": [
                    { "type":"vendor",
                        "displayName": "JP Morgan Chase",
                        "rates": [
                                {  "name": "E-Check",       "amount": "0" },
                                {  "name": "Credit Card",   "rate":   "0.0225", "minimum": "0.01",  "maximum": "" },
                                {  "name": "Debit Card",    "amount": "3.50" }
                                ]
                    },
                    { "type":"ach",
                        "displayName": "E-Check",
                        "rates": [
                                {  "name": "E-Check",       "amount": "0" }
                                ]
                    },
                    { "type":"cc",
                        "rates": [
                                {  "name": "Credit Card",   "rate": "0.0198",   "minimum": "0",     "maximum": "" }
                                ]
                    }
                    ],
            "method": { "type":"vendor",
                        "displayName": "JP Morgan Chase",
                        "rates": [
                                {  "name": "E-Check",       "amount": "0" },
                                {  "name": "Credit Card",   "rate":   "0.0225", "minimum": "0.01",  "maximum": "" },
                                {  "name": "Debit Card",    "amount": "3.50" }
                                ]
                    },
            "contact":{
                    "country":"",
                    "name":"test test",
                    "street":"123 any street",
                    "city":"San Antonio",
                    "state":"TX",
                    "zipcode":"12345",
                    "phone":"8005551121",
                    "email":"a@a.com",
                    "vemail":"a@a.com"
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
