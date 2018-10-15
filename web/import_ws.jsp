<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 10/8/2018
  Time: 10:55 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc"
%><%
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

    try {

            sitSale = SITSale.initialContext().set("P138386","10.02.2018","2019","Lexus","1234567890","MV","test","25000","55","2000","2018","08","O",reportSequence,"Y","10.15.2018","Claude").addSale(datasource);

    } catch (Exception e){
        out.println( e.toString());
    }


%>
