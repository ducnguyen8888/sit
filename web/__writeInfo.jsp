<%--
    DN - 08/07/2018 - PRC 198408
        - Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
    DN - 09/12/2018 - PRC 197579
        - Updated code, all of insert, delete and update requests won't be executed if the users have the "view only" right
    DN - 10/26/2018 - PRC 208710
        - Updated the functionality "Create New Record" by using web service(add/delete/edit)
--%><%@ include file="_configuration.inc"%>
<%

SITUser     sitUser     = sitAccount.getUser();
SITSale     sitSale     = SITSale.initialContext();
boolean     wasPosted   = "POST".equals(request.getMethod());

String      saleDate        = nvl(request.getParameter("date_of_sale"));
String      modelYear       = nvl(request.getParameter("model_year"));
String      make            = nvl(request.getParameter("make"));
String      vinSerialNo     = nvl(request.getParameter("vin_serial_no"));
String      saleType        = nvl(request.getParameter("sale_type"));
String      purchaserName   = nvl(request.getParameter("purchaser_name"));
String      salesPrice      = nvl(request.getParameter("sales_price"));
String      taxAmount       = nvl(request.getParameter("tax_amount"));
String      reportSeq       = nvl(request.getParameter("report_seq"));
String      salesSeq        = nvl(request.getParameter("sales_seq"));
String      status          = nvl(request.getParameter("status"));
            form_name       = nvl(request.getParameter("form_name"));
String      uptvFactor      = nvl(request.getParameter("uptv_factor"));
String      pendingPayment  = nvl(request.getParameter("pending_payment"));
String      inputDate       = nvl(request.getParameter("input_date"));
String      action          = nvl(request.getParameter("action"));
            dealerType      = nvl(request.getParameter("dealer_type"));


// PRC 197579 - Updated code, all of insert, delete and update requests won't be executed if the users have the "view only" right
if( sitUser.isValid()
        && wasPosted
        && !viewOnly
        && isDefined(action)) {
    String saleResponse = "{\"saleRecordRequest\":\"success\",\"data\":{\"%s\":\"%s\",\"detail\":\"%s\"}}";

    if ( "delete".equals(action)
            && isDefined(year)
            && isDefined(month)
            && isDefined(salesSeq) ) {
        // ************** DELETE **************
            month = month.length() == 1 ? "0" + month : month; // makes 7 = 07
            try {
                sitSale.setClientId(sitUser.getClientId())
                            .setCan(can)
                            .setYear(year)
                            .setMonth(month)
                            .setSalesSeq(salesSeq)
                        .removeSale(datasource);
                out.println(String.format(saleResponse, "deleteSaleRecord", "success", "The sale record is successfully deleted"));
            } catch (Exception e) {
                out.println(String.format(saleResponse, "deleteSaleRecord", "failure", e.getMessage().toString()));
            }

    } else if ( "edit".equals(action)
                    && isDefined(year)
                    && isDefined(month)
                    && isDefined(salesSeq) ) {
        // ************** EDIT **************
        // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
            month = month.length() == 1 ? "0" + month : month; // makes 7 = 07
            try {
                sitSale.setSaleDate(saleDate)
                            .setModelYear(modelYear)
                            .setMake(make)
                            .setVinNo(vinSerialNo)
                            .setSaleType(saleType)
                            .setBuyerName(purchaserName)
                            .setSalesPrice(salesPrice)
                            .setTaxAmount(taxAmount)
                            .setInputDate(inputDate)
                            .setOpercode(sitUser.getUserName())
                            .setYear(year)
                            .setMonth(month)
                            .setClientId(sitUser.getClientId())
                            .setCan(can)
                            .setSalesSeq(salesSeq)
                        .updateSale(datasource);
                out.println(String.format(saleResponse, "updateSaleRecord", "success", "The sale record is successfully updated"));
            } catch (Exception e) {
                out.println(String.format(saleResponse, "updateSaleRecord", "failure", e.getMessage().toString()));
            }
    } else if ( "new".equals(action)
                    && isDefined(year)
                    && isDefined(month)
                    && isDefined(taxAmount) ) {
        // ************** NEW **************
            month = month.length() == 1 ? "0" + month : month; // makes 7 = 07
            try {
                sitSale.set(can, saleDate,
                                modelYear, make,
                                vinSerialNo, saleType,
                                purchaserName, salesPrice,
                                taxAmount, sitUser.getClientId(),
                                year, month,
                                status, reportSeq,
                                pendingPayment, inputDate,
                                sitUser.getUserName())
                        .addSale(datasource);
                out.println(String.format(saleResponse, "addSaleRecord", "success", "The sale record is successfully added"));
            } catch (Exception e) {
                out.println(String.format(saleResponse, "addSaleRecord", "failure", e.getMessage().toString()));
            }


    }  else {
        out.println(String.format("{\"saleRecordRequest\":\"failure\",\"detail\":\"Not all required information is provided\"}"));
    }
} else {
    out.println(String.format("{\"saleRecordRequest\":\"failure\",\"detail\":\"Request can not be processed\"}"));
}

%>


