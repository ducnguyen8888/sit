<%--
    DN - PRC 194602 -  05/30/2018 ( This requirement will be moved with this PRC)
        - Split payment processing into each client own payment directory
--%><%@ include file="_configuration.inc" %><%! 
    public StringBuffer getDealerAddress(Dealership d){
        StringBuffer sb = new StringBuffer();
        if (isDefined(d.nameline1)){sb.append("<a id = \"" + d.can + "\" class = \"" + d.dealerType + "\" href=\"#\">" + d.nameline1 + "</a>");}
        if (isDefined(d.nameline2)){sb.append("<br>" + d.nameline2);}
        if (isDefined(d.nameline3)){sb.append("<br>" + d.nameline3);}
        if (isDefined(d.nameline4)){sb.append("<br>" + d.nameline4);}
        sb.append("<br>" + nvl(d.city) + ", " + nvl(d.state) + " " + formatZip(d.zipcode));
        if (isDefined(d.phone)){sb.append("<br>Phone: " + formatPhone(d.phone));}
        sb.append("<br>Acct: " + d.aprdistacc);
        return sb;
    }
/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
    
%><%
    PreparedStatement ps         = null;
    CallableStatement cs         = null;
    ResultSet         rs         = null;
    Connection        conn       = null;
    ResultSetMetaData rsmd       = null;
    java.text.DecimalFormat df = new java.text.DecimalFormat("$###,###,##0.00");

    String [] monthsText           = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
    
    // PRC 194602 Split payment processing into each client own payment directory
    String              client_id           = (String) session.getAttribute("client_id");
    String              cfgName             = "";
    
    if ( "2000".equals( client_id ) ) {
        cfgName = "sitHarris";
    } else if ( "7580".equals( client_id ) ) {
        cfgName = "sitDallas";
    } else if ( "79000000".equals( client_id ) ) {
        cfgName = "sitFbc";
    } else if ( "94000000".equals( client_id ) ) {
        cfgName = "sitElpaso";
    } else if ( "98000000".equals( client_id ) ) {
        cfgName = "sitGalveston";
    }
    
    AppConfiguration    configuration           = new AppConfiguration(pageContext, cfgName);
    String              webPaymentDirectory     = configuration.getProperty("webPaymentDirectory");
    //conn = act.util.Connect.open("jdbc/sit_dev");
    StringBuffer sb = new StringBuffer();
    String pageTitle = "Shopping Cart";
   // if (isDefined(request.getParameter("can"))){
   //     recents.add(request.getParameter("can"), request.getParameter("name"));
   // }
  
%><%@ include file="_top1.inc" %>
<style>
    #main table {margin-left:60px;}
    #instruction{padding-top: 30px; padding-bottom: 30px; font-size: 1.2em;}
    #sideBar {bottom: 15px;}
    #body{top: 153px; margin:0px;}
    .dataTable{ margin-left: 20px; margin-bottom: 15px; width: 700px;}
    .dataTable tr th { border: 1px solid black; padding: 3px; text-align:left; background: #edf3fe; }
    .dataTable tr td { border: 1px solid black; padding: 3px; text-align:center; }
    .dataTable tr:nth-child(odd) td { background: white; }
    .dataTable tr:nth-child(even) td { background: #edf3fe; }
    .aLeft { text-align: left !important; }
    .aRight { text-align: right !important; }    
</style>
<%@ include file="_top2.inc" %>
<%= recents %><!-- include here for "recents" sidebar -->

<!-- *** this loads up the class *** -->
<% /*@ include file="SITPayments.txt" */%>
<!-- ******************************* -->
    <div id="body">
        <div id="main" style="margin-top: 0px;">
        <%  String goToPage = "Payments Due";
            if (isDefined(request.getParameter("current"))) {
                if("yearlySummary.jsp".equals(request.getParameter("current"))){
                    goToPage = "Yearly Summary";
                } else if("confirmTotals.jsp".equals(request.getParameter("current"))){
                    goToPage = "Totals";
                } else if("sales.jsp".equals(request.getParameter("current"))){
                    goToPage = "Sales";
                }
            } 
        %>

            <a style="margin: 30px; " id="btnBack" name="btnBack" class="btn btn-primary" href="paymentsDue.jsp">Back to <%= goToPage %></a>

<form action="webpay/<%= webPaymentDirectory %>/payment.jsp">
<%


//if(isDefined(request.getParameter("addToCart"))){
//    String [] cartStuff = request.getParameterValues("toPay[]");
//    String [] tempItem = new String[3];
//    String description = "";
//    for(String c : cartStuff){
//        tempItem=c.split("\\|");
//        description =  (monthsText[Integer.parseInt(tempItem[2])] + " " + tempItem[1]);
//        payments.add(new Payment(tempItem[0], tempItem[1], tempItem[2], description, tempItem[3], "0.0", tempItem[3], tempItem[3], "0.00"));
//
//    }
//    //out.print(s[0]);
//}

    // receives and adds to cart from yearlyStatement page
    //if(isDefined(request.getParameter("can"))){
    //    String theCan = request.getParameter("can");
    //    String theYear = request.getParameter("year");
    //    String description = "";        
    //    List<String> months = Arrays.asList(request.getParameter("month").split("\\s*,\\s*")); 
    //    List<String> totals = Arrays.asList(request.getParameter("totals").split("\\s*,\\s*")); 
    //    try{
    //        String tempTotal = "";
    //        // Capture incoming items to add to cart
    //        for (int i = 0; i < months.size(); i++){
    //            tempTotal = totals.get(i);
    //            description =  (monthsText[Integer.parseInt(months.get(i))] + " " + theYear);
    //            payments.add(new Payment(theCan, theYear, months.get(i), description, tempTotal, "0.0", tempTotal, tempTotal, "0.00"));
    //        }
    //    } catch(Exception e){out.print("Exception: " + e.toString());}
    //}
    if(payments.size() > 0){
        ArrayList<Payment> al = new ArrayList<Payment>();
        d = new Dealership();
        int accountColSpan = sitAccount.SHOW_CAD_NO_IN_SIT_PORTAL ? 6 : 5;
        int totalPayColSpan = accountColSpan -2;
        out.print("<table class='dataTable' id='payments'>");
            for (int i = 0 ; i < ds.size() ; i++){
                d = (Dealership) ds.get(i);
                if(payments.doesExist(d)){
                    out.print("<tr><td colspan='"+ accountColSpan +"' style='font-weight: bold;background:#BBC7CE;'>" + d.nameline1 + " - " + d.can + "</td></tr>");
                    out.print("      <tr>");
                    out.print("          <td>Account</td>");
                    out.print(           sitAccount.SHOW_CAD_NO_IN_SIT_PORTAL ? ("<td>CAD No</td>"):"");
                    out.print("          <td>Year</td>");
                    out.print("          <td>Month</td>");
                    out.print("          <td>Balance</td>");
                    out.print("          <td>&nbsp;</td>");
                    out.print("      </tr>");
                    al = payments.getPaymentsForForm(d.can);
                    for (Payment str : al) {
                        out.print("<tr>");
                        out.print("    <td class='can'>"+str.getCan()+"</td>");
                        out.print(     sitAccount.SHOW_CAD_NO_IN_SIT_PORTAL ? ("<td>" + d.aprdistacc + "</td>"):"");
                        out.print("    <td class='year'>"+str.getYear()+"</td>");
                        out.print("    <td class='month'>"+str.getMonth()+"</td>");
                        out.print("    <td class='amountDue'>"+df.format(Double.parseDouble(str.getAmountDue()))+"</td>");
                        out.print("    <td><button type='submit' class='btnDel'>Delete</button></td>");
                        out.print("</tr>");
                    }
                    out.print("<tr><td colspan='5' style='background:none;border-left:none;border-right:none;'>&nbsp;</td></tr>");
                }//if
            }//for
%>

        <tr>
            <td colspan='<%= totalPayColSpan %>' align="right" style="border-right:none;"><div style='font-weight: bold; padding-right:3px;width: 400px;text-align:right;'>Total to pay: </div></td>
            <td style='font-weight:bold;border-right:none;border-left:none;'><span id='total_to_pay'></span></td>
            <td style='border-left:none;'>&nbsp;</td>
        </tr>
        <tr>
            <td colspan='<%= totalPayColSpan %>' align="right" style='background:none; border:none;'><div style='font-weight: bold; padding-right:3px;width: 400px;text-align:right;'>&nbsp;</div></td>
            <td style='background:none; border:none;'><button type='submit' id='paynow'>Pay Now</button></td>
            <td style='background:none; border:none;'>&nbsp;</td>
        </tr>
    </table>

    <%
        } else {
            out.print("<span style='font-weight:bold;padding-left: 150px;'>No items in cart</span>");
        }
    %>

            </form>
            <form id="tabNav" action="yearlySummary.jsp" method="post">
                <input type="hidden" id="can" name="can" value="<%= can %>" />
                <input type="hidden" id="category" name="category" value="" />      
                <input type="hidden" id="year" name="year" value="" />  
            </form>
            <div id="helpDiv"></div>
            <form id="navigation" action="yearlySummary.jsp" method="post">
                <input type="hidden" name="can"   id="can"   value="<%= request.getParameter("can") %>">
                <input type="hidden" name="name"  id="name"  value="<%= request.getParameter("name") %>">
                <input type="hidden" name="totals" id="totals" value="">
                <input type="hidden" name="month" id="month" value="<%= request.getParameter("month") %>">
                <input type="hidden" name="year"  id="year"  value="<%= request.getParameter("year") %>">
                <input type="hidden" name="client_id"  id="client_id"  value="<%= request.getParameter("client_id") %>">
                <input type="hidden" name="current" id="current" value="<%= current_page %>">
                <input type="hidden" name="category"  id="category"  value="<%= category %>">
                <input type="hidden" id="report_seq"   name="report_seq"   value="<%= request.getParameter("report_seq") %>" >

            </form>
        </div><!-- div.main -->
    </div><!-- div.body -->
    <!-- jQuery and Bootstrap --> 
    <script src="assets/js/jquery.min.js"></script> 
    <script src="assets/js/bootstrap.min.js"></script>
    <script src="assets/js/jquery-ui.min.js"></script> 
    <script src="assets/js/various.js?<%= (new java.util.Date()).getTime() %>"></script>
<!-- include scripts here -->
<script src="assets/js/jquery.tablesorter.min.js"></script> 
    <script>
        $(document).ready(function() {
            //function calcTotal(){
            //    var total=0.0;
            //    $("table.dataTable").find("td.amountDue").each(function(){
            //        var value = parseFloat($(this).html().replace('$',''));
            //        if (!isNaN(value)) {
            //            total += value;
            //        }
            //    });
            //    $("#total_to_pay").text("$" + total.toFixed(2));    
            //}
            
            function calcTotal(){
                var total=0.0;
                $("table.dataTable").find("td.amountDue").each(function(){
                    var value = parseFloat($(this).html().replace(/[$,]/g,''));
                    if (!isNaN(value)) {
                        total += value;
                    }
                });
               
                $("#total_to_pay").text("$" + total.toFixed(2).replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,"));
            }
            calcTotal();
            
            $(document).on("click", ".btnDel", function(e){

                e.preventDefault();
                e.stopPropagation();
                var $theRow = $(this).parent().parent();
                // get values from this row
                var can          = $theRow.find(".can").text();
                var year         = $theRow.find(".year").text();
                var month        = $theRow.find(".month").text();
                var action = "remove";
                $(this).append('<span>submitting...</span>');
                $(this).css('display', 'none');
                $.ajax({
                    type: "GET",
                    url: '_paymentsAjax.jsp',
                    data: { can: can, year: year, month: month, action: action },
                    contentType: "application/json; charset=utf-8",
                    success: successFunc,
                    error: errorFunc
                });
                function successFunc(data, status) { 

                    var toDelete = $theRow.find("td.amountDue").text().replace('$','');
                    var originalAmount = $("#total_to_pay").text().replace('$','').replace(',','');
                    $("#total_to_pay").text("$" + (originalAmount - toDelete).toFixed(2));
                    // PRC 194602 - 05/30/2018
                    // The "Pay Now" button will be disabled when all accounts in cart are removed
                    if ( (originalAmount - toDelete) === 0 ) {
                        $("#paynow").prop("disabled", true);
                    }
                    $theRow.remove(); 
                }
                function errorFunc(data, status) { console.log('status: ' + status); }
                //console.log("DELETE: can: " + can + ", year: " + year + ", month: " + month);

                // delete row
                
                //re-calculate total
                calcTotal();
            });
              $("table#recentsTable a").click(function(e) {
                e.preventDefault();
                e.stopPropagation();
                console.log("clicked");
                var can = $(this).text();
                var name = $(this).parent().children("#sidebarRecent").text();
                var theForm = $("form#navigation");
                theForm.children("input#can").prop("value", can);
                theForm.children("input#name").prop("value", name);
                theForm.prop("action", "yearlySummary.jsp");
                theForm.submit();
            });  
            $("#feedback a").click(function(e) {
                e.preventDefault();
                e.stopPropagation();
                var theForm = $("form#navigation");
                theForm.prop("method", "post");
                theForm.prop("action", "feedback.jsp");
                theForm.submit();
            });              
            $("#btnBack").on("click", function(e){
                e.preventDefault();
                e.stopPropagation();
                //console.log("clicked a tab");
                var goToPage = "<%= (isDefined(request.getParameter("current")) ? request.getParameter("current") : "paymentsDue.jsp") %>";
                var $theForm = $("form#navigation");
                $theForm.prop("action", goToPage);
                //$theForm.children("input#can").prop("value", can);
                //$theForm.children("input#year").prop("value", theYear);
                $theForm.submit();
            });

        });
    </script>
</body>
</html>
<% 
//    conn.close(); conn = null; 
%>