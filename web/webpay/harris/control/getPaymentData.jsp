<%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");


%>{"status":"OK",
    "payment":
{
            "isTest":true,
            "CID":"7580",
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
                    "street":"123 test street",
                    "city":"san antonio",
                    "state":"TX",
                    "zipcode":"78232",
                    "phone":"(800) 555-1212",
                    "email":"a@a.com",
                    "vemail":"a@a.com"
                },

                "name": "",
                "username": "",
                "client": "",
                "client_id": "",
                "dealers": [{
                                "can": "8888",
                                "nameline1": "DAWNS CARS AND TRUCKS",
                                "nameline2": "100 MAIN STREET",
                                "nameline3": "null",
                                "nameline4": "null",
                                "city": "CITY",
                                "state": "TX",
                                "zipcode": "78070",
                                "payment": [{
                                                "description": "January 2015",
                                                "reportSeq": "1",
                                                "month": "1",
                                                "year": "2015",
                                                "amountDue": "23.94",
                                                "amountPending": "0.0",
                                                "paymentAmount": "23.94",
                                                "minPayment": "23.94",
                                                "maxPayment": "0.00"
                                }]
                }, {
                                "can": "H000001",
                                "nameline1": "ALLRED EQUIPMENT INC",
                                "nameline2": "ATTN: GARY ALLRED",
                                "nameline3": "PO BOX 1165",
                                "nameline4": "null",
                                "city": "ROSENBERG",
                                "state": "TX",
                                "zipcode": "77471-1165",
                                "payment": [{
                                                "description": "May 2016",
                                                "reportSeq": "1",
                                                "month": "5",
                                                "year": "2016",
                                                "amountDue": "38.07",
                                                "amountPending": "0.0",
                                                "paymentAmount": "38.07",
                                                "minPayment": "",
                                                "maxPayment": "0.00"
                                }, {
                                                "description": "April 2016",
                                                "reportSeq": "3",
                                                "month": "4",
                                                "year": "2016",
                                                "amountDue": "327.55",
                                                "amountPending": "0.0",
                                                "paymentAmount": "327.55",
                                                "minPayment": "197.55",
                                                "maxPayment": "0.00"
                                }, {
                                                "description": "March 2016",
                                                "reportSeq": "1",
                                                "month": "3",
                                                "year": "2016",
                                                "amountDue": "33.29",
                                                "amountPending": "0.0",
                                                "paymentAmount": "33.29",
                                                "minPayment": "",
                                                "maxPayment": "0.00"
                                }]
                }, {
                                "can": "H000002",
                                "nameline1": "HLAVINKA EQUIPMENT CO",
                                "nameline2": "P O BOX 1335",
                                "nameline3": "null",
                                "nameline4": "null",
                                "city": "EAST BERNARD",
                                "state": "TX",
                                "zipcode": "77435-1335",
                                "payment": [{
                                                "description": "December 2013",
                                                "reportSeq": "1",
                                                "month": "12",
                                                "year": "2013",
                                                "amountDue": "10750.61",
                                                "amountPending": "0.0",
                                                "paymentAmount": "10750.61",
                                                "minPayment": "10750.61",
                                                "maxPayment": "0.00"
                                }]
                }]
}
}