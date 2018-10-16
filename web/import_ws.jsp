<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 10/8/2018
  Time: 10:55 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc"
%><%
    boolean  wasPosted                 = "POST".equals(request.getMethod());
    String   reportSequence            = nvl(request.getParameter("report_seq"), "1");

    String[] dos                       = (isDefined(request.getParameter("sale"))) ? request.getParameterValues("sale")
                                                                                    : new String[0];

    String[] model                     = (isDefined(request.getParameter("model")))? request.getParameterValues("model")
                                                                                    : new String[0];

    String[] make                      = (isDefined(request.getParameter("make"))) ? request.getParameterValues("make")
                                                                                    : new String[0];

    String[] vin                       = (isDefined(request.getParameter("vin")))  ? request.getParameterValues("vin")
                                                                                    : new String[0];

    String[] type                      = (isDefined(request.getParameter("type"))) ? request.getParameterValues("type")
                                                                                    : new String[0];

    String[] purchaser                 = (isDefined(request.getParameter("name"))) ? request.getParameterValues("name")
                                                                                    : new String[0];

    String[] price                     = (isDefined(request.getParameter("price")))? request.getParameterValues("price")
                                                                                    : new String[0];

    String[] tax                       = (isDefined(request.getParameter("tax")))  ? request.getParameterValues("tax")
                                                                                    : new String[0];

    String[] calculated                = (isDefined(request.getParameter("calculated")))? request.getParameterValues("calculated")
                                                                                        : new String[0];

    String inputDate                   = (isDefined(request.getParameter("inputDate")))? request.getParameter("inputDate")
                                                                                        : "01/01/1999";

    SITSale sitSale                    = null;

    if ( sitAccount.isValid()
            && wasPosted ){
        if ( isDefined(can)
             && isDefined(year)
             && isDefined(month)
             && isDefined(request.getParameter("calculated")) ) {
            try {
                for (int i = 0; i < dos.length; i++) {
                    sitSale = SITSale.initialContext().set(can, dos[i],
                                                            model[i], make[i],
                                                            vin[i], type[i],
                                                            purchaser[i], numberFormat(price[i]),
                                                            numberFormat(calculated[i]), sitAccount.getClientId(),
                                                            year, month, "O",
                                                            reportSequence, "Y",
                                                            inputDate, sitAccount.getUser().getUserName())
                                                      .addSale(datasource);
                }

                out.println(" {\"importSalesRecordRequest\":\"success\",\"data\":{\"importSalesRecord\":\"success\",\"detail\":\"The sales record is successfully imported\"}}");

            } catch (Exception e) {
                out.println(e.toString());
            }
        } else {
            out.println(String.format("{\"importSalesRecordRequest\":\"failure\",\"detail\":\"Not all required information is provided\"}"));
        }
    } else {
        out.println(String.format("{\"importSalesRecordRequest\":\"failure\",\"detail\":\"Request can not be processed\"}"));
    }

%>
