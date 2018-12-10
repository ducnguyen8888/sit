<%--
    DN - 1/10/2018 - PRC 195487 
        Added the function to check if the document image record is saved into sit_document_images table
        Updated the logic. We only update the document image record in  sit_document_images table if document exists and the document image record is saved. If not, we have to add a new one into sit_document_images table
    DN - 05/16/2018 - PRC 194431
        Harris County wants the "Go to Cart" button to be displayed after the form is finalized even though Harris County is not "Finalized on Pay"
    DN - 08/07/2018 - PRC 198588
        Moved getClientPref and getSitClientPref function to "_configuation.inc" file
    DN - 08/07/2018 - PRC 198408
        -Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
    DN - 11/05/2018 - PRC 209149
        Use client prefs JUR_ADDRESS1, JUR_ADDRESS2, JUR_ADDRESS4, JUR_EMAIL_ADDRESS, JUR_PHONE1 to control the tax office information in the confirmation email
--%><%
    java.util.Calendar cal  = java.util.Calendar.getInstance();
    java.text.DateFormat dateFormat = new java.text.SimpleDateFormat("MMddyyyyHHmmss");
    String fileTime        = dateFormat.format(cal.getTime()); //a-key_seq-timestamp
  
  
    SITUser    sitUser      = sitAccount.getUser();

  
    can                     = request.getParameter("can");
    year                    = request.getParameter("year");
    month                   = request.getParameter("month");
    month                   = month.length() == 1 ? "0" + month : month; // makes 7 = 07

    SITStatement monthlyStatement = new MonthlyStatement();
    
    String description      = MonthlyStatement.months[Integer.parseInt( month )] + " " + year + " SALES REPORT - WEB";
    String preNote          = "Monthly Sales Report for "+ month +"/"+ year +" finalized on ";
    
    String emailSubject     = MonthlyStatement.months[Integer.parseInt( month )] + " " + year + " SALES REPORT";
    String emailFrom        = nvl(configuration.getProperty("JUR_EMAIL_ADDRESS"),sitAccount.JUR_EMAIL_ADDRESS);
    String emailTo          = nvl(sitUser.email,"duc.nguyen@lgbs.com");
    
    String jurAddress1      = nvl(configuration.getProperty("JUR_ADDRESS1"),sitAccount.JUR_ADDRESS1);
    String jurAddress2      = nvl(configuration.getProperty("JUR_ADDRESS2"),sitAccount.JUR_ADDRESS2);
    String jurAddress4      = nvl(configuration.getProperty("JUR_ADDRESS4"),sitAccount.JUR_ADDRESS4);
    String jurPhone1        = nvl(configuration.getProperty("JUR_PHONE1"),sitAccount.JUR_PHONE1);

 
  try {
      monthlyStatement.set( datasource, sitAccount.getClientId(),
                            can, month, year, sitUser.getUserName(),"MONRPT",report_sequence,description,preNote, fileTime,
                            tempDirectory,start.toString() +  end.toString(),
                            pdfConverterURL,
                            emailSubject,
                            emailFrom,
                            emailTo,
                            jurAddress1,
                            jurAddress2,
                            jurAddress4,
                            jurPhone1 )
                        .setRootPath("")
                        .setPayments( payments )
                        .setFinalizeOnPay( finalize_on_pay )
                        .closeStatement();
  } catch ( Exception e){
      throw e;
  }
 
 %>