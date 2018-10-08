<%--
    DN - 05/30/2018
        - Split payment processing into each client own payment directory
    DN - 10/02/2018 - PRC 205088
        - Added CAD No
        - Display "CAD No" controlled by codeset "SHOW_CAD_NO_IN_SIT_PORTAL"
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
    java.text.DecimalFormat df = new java.text.DecimalFormat("$###,###,##0.00");
    java.text.DecimalFormat payFormat = new java.text.DecimalFormat("########0.00");

    StringBuffer sb = new StringBuffer();
    String pageTitle = "Payments Due";
  
%><%@ include file="_top1.inc" %>
<style>
    /*#main table {margin-left:60px;}*/
    #instruction{padding-top: 30px; padding-bottom: 30px; font-size: 1.2em;}
    #sideBar {bottom: 15px;}
    #body {top: 153px; margin:0px;}
    
    /*.dataTable{ margin-left: 20px; margin-bottom: 15px; width: 700px;}*/
    /*.dataTable{ margin: 0px;  width: 700px;}*/
    .dataTable{ margin: 0px;  }
    .fixed_headers tr th { border: 1px solid black;text-align:left; background: #edf3fe; }
    .fixed_headers tr td { border: 1px solid black;text-align:center; }
    .dataTable tr:nth-child(odd) td { background: white; }
    .dataTable tr:nth-child(even) td { background: #edf3fe; }
    .aLeft { text-align: left !important; }
    .aRight { text-align: right !important; }  
    .ui-accordion .ui-accordion-content{ overflow:hidden !important; }



.fixed_headers {
  width: 820px;
  table-layout: fixed;
  /*border-collapse: collapse;*/
}

.fixed_headers th,
.fixed_headers td {
  padding: 5px;
  text-align: left;
}
.fixed_headers td:nth-child(1),   /* can */
.fixed_headers th:nth-child(1) {
  min-width: 150px;
}
.fixed_headers td:nth-child(2),   /* year */
.fixed_headers th:nth-child(2) {
  min-width: 60px;
}
.fixed_headers td:nth-child(3),   /* month */
.fixed_headers th:nth-child(3) {
  width: 60px;
}
.fixed_headers td:nth-child(4),   /* levy balance */
.fixed_headers th:nth-child(4) {
  width: 120px;
}
.fixed_headers td:nth-child(5),   /* penalty balance */
.fixed_headers th:nth-child(5) {
  width: 85px;
}
.fixed_headers td:nth-child(6),   /* fines */
.fixed_headers th:nth-child(6) {
  width: 75px;
}
.fixed_headers td:nth-child(7),   /* nsf */
.fixed_headers th:nth-child(7) {
  width: 75px;
}
.fixed_headers td:nth-child(8),   /* total */
.fixed_headers th:nth-child(8) {
  width: 120px;
}
.fixed_headers td:nth-child(9),   /* pay */
.fixed_headers th:nth-child(9) {
  width: 50px;
}
/*.fixed_headers td:nth-child(10),
.fixed_headers th:nth-child(10) {
  width: 100px;
}*/
.fixed_headers thead {
  background-color: #edf3fe;
  /*color: #FDFDFD;*/
}
.fixed_headers thead tr {
  display: block;
  position: relative;
}
.fixed_headers tbody {
  display: block;
  overflow: auto;
  width: 100%;
  height: 300px;
}
.fixed_headers tbody tr:nth-child(even) {
  background-color: #edf3fe;
}
.old_ie_wrapper {
  height: 300px;
  width: 820px;
  overflow-x: hidden;
  overflow-y: auto;
}
.old_ie_wrapper tbody {
  height: auto;
}





</style>
    <link href="assets/jquery2-ui.min.css" rel="stylesheet">

<%@ include file="_top2.inc" %>
<%= recents %><!-- include here for "recents" sidebar -->
<div id="body">
    <div id="main" style="margin-top: 0px;">
        <%  String goToPage = "Dealerships";
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
        <a style="margin: 30px; " id="btnBack" name="btnBack" class="btn btn-primary" href="dealerships.jsp">back to <%= goToPage %></a>
            <a style="margin: 30px; margin-left: 520px" id="btnContinue" name="btnContinue" class="btn btn-primary" href="pay.jsp">Continue to Cart</a>
        <!--PRC 194603 Added note -->
        <div id="note">
            Note: Sales totals for all other sales types are shown on each month's statement page.
        </div>

   <div id="tableBody" >
        <style>
            #note { color: red; padding-left: 150px; font-size: 14px; }
            #tableBody { position: absolute; top: 130px; left: 0px; right 100px; bottom 20px; overflow-x:hidden; overflow-y: auto; }
            #dataTable { border-collapse:collapse; margin-left: 80px; xborder: 1px solid black; }
            #dataTable thead tr:nth-child(odd) { background-color: #e4eFfD; }
            #dataTable tbody tr:nth-child(odd) { background-color: white; }
            #dataTable tbody tr:nth-child(even) { background-color: #e4eFfD; }

            #dataTable th, #dataTable td {
                vertical-align: middle; text-align: center; white-space: nowrap;
                padding: 3px 3px; border: 1px solid black; height: 20px; min-height: 40px; max-height: 40px;
                font-size: 12px; 
            }
            #dataTable th:first-child {
                width: 80px;  min-width: 70px;
            }
            #dataTable td:first-child {
                padding-top: 5px; padding-bottom: 5px; width: 70px;  min-width: 70px;
            }
            #dataTable th:nth-child(1n+3), #dataTable td:nth-child(1n+3) {
                text-align: right; min-width: 75px;
            }
            #dataTable th:nth-child(1n+9), #dataTable td:nth-child(1n+9) {
                text-align: center; min-width: 65px;
            }
            #dataTable td.paymentCompleted { color: green; }

            #dataTable tfoot tr th:first-child, #dataTable tfoot tr td { background-color: #F9F88A; border: 1px solid black; }
            #dataTable tfoot th, #dataTable tfoot td {
                text-align: right; padding: 8px 3px;
            }
            #dataTable tfoot th:nth-child(1n+1) {
                background-color: none; border: none;
            }

            #dataTable tbody#loading td { padding: 0px; }
            #dataTable tbody#loading td div { text-align:center; height: 240px; width: 600px; padding-top: 100px; font-size: 20px; font-style:italic; background-color: #b0b0b0; }

            #dataTable tbody tr:last-child td { border: none !important; background: transparent; background-color: none !important; }
            #dataTable tbody tr:last-child { border: none !important; background: transparent; background-color: none !important; }
            #dataTable tfoot tr { border: none; }
            #dataTable thead, #dataTable tfoot { display: none; }
            #dataTable tbody tr:first-child td { border: none !important; background: transparent; background-color: none !important;
                        text-align: left; padding: 10px 6px; font-weight: normal; font-size: 15px;
            }
        </style>
        <div id="myTableDiv">
            <table id=dataTable>
            <thead>
                <tr> <th> Year </th> <th> Month </th> 
                     <th> Levy Due </th> <th> Pen Due </th> <th> Fines Due </th> <th> NSF Due </th> <th> Total Due </th> 
                     <th> Pay </th> 
                </tr>
            </thead>
            <tbody id="loading">
                <tr> <td colspan=12>
                        <div>
                            Loading, please wait...
                        </div>
                     </td>
                </tr>
            </tbody>
            <tfoot>
                <tr> <th colspan=2> Dealer Totals: </th> <td> </td>
                     <td> </td> <td> </td> <td> </td> <td> </td> </th>
                </tr>
            </tfoot>
            </table>
          <!--<div id="testDiv" style='margin-left: 60px;'></div>-->
        </div>
    </div><!-- /body -->
  

    <form id="tabNav" action="yearlySummary.jsp" method="post">
        <input type="hidden" id="can" name="can" value="<%= can %>" />
        <input type="hidden" id="category" name="category" value="" />      
        <input type="hidden" id="year" name="year" value="" />
        <input type="hidden" id="showCad" name="showCad" value="<%= sitAccount.SHOW_CAD_NO_IN_SIT_PORTAL %>">
    </form>
    <div id="helpDiv"></div>
        <form id="navigation" action="yearlySummary.jsp" method="post">
        <input type="hidden" name="can"   id="can"   value="<%= request.getParameter("can") %>">
        <input type="hidden" name="name"  id="name"  value="<%= request.getParameter("name") %>">
        <input type="hidden" name="totals" id="totals" value="">
        <input type="hidden" name="month" id="month" value="<%= request.getParameter("month") %>">
        <input type="hidden" name="year"  id="year"  value="<%= request.getParameter("year") %>">
        <input type="hidden" name="client_id"  id="client_id"  value="">
        <input type="hidden" name="current" id="current" value="<%= current_page %>">
        <input type="hidden" name="category"  id="category"  value="<%= request.getParameter("category") %>">
        <input type="hidden" id="report_seq"   name="report_seq"   value="<%= request.getParameter("report_seq") %>" >
    </form>
    <!-- jQuery and Bootstrap --> 
    <script src="assets/js/jquery.min.js"></script> 
    <script src="assets/js/bootstrap.min.js"></script>
    <script src="assets/jquery2-ui.min.js"></script> 
    <script src="assets/js/various.js?<%= (new java.util.Date()).getTime() %>"></script>

<!-- include scripts here -->
<script src="assets/js/jquery.tablesorter.min.js"></script> 
<script src="assets/js/jquery.color-2.1.2.min.js"></script> 
    <script type="text/javascript" src="assets/js/sitcommon.js"></script>
    <script type="text/javascript" src="paymentsDue.js?<%= (new java.util.Date()).getTime() %>"></script>
    <script>
        var paymentsDue = {};
        $(function() 
            {
                $.post( "paymentsDue_ws.jsp", { "can": $("#can").val() } )
                        .done(
                            function (data, status, jqxhr)
                            {
                                console.log("Done response");
                                //console.log(data);
                                try
                                {
                                    paymentsDue = JSON.parse(data);
                                    displayPaymentsDue();
                                }
                                catch (err)
                                {
                                    alert("Failed to complete your request:<br><br>"+err);
                                }
                            }
                        )
                        .fail(
                            function (data, status, jqxhr)
                            {
                                alert("Failed to verify account, processing error: ");
                                console.log($("#loginMessages .errors").html()+jqxhr.status);
                            }
                        )
                        .always(
                            function (data, status, jqxhr)
                            {
                            }
                        );

                $("#yearSelect").change(function() { displayYear($(this).val(),yearlyData); });
            }
        );
    </script>

    <script>
        $(document).ready(function() {
            //$( "#accordion" ).accordion({heightStyle: "content"});
            $( "#accordion" ).accordion({heightStyle: "fill", 'clearStyle': true});
            var $theForm = $("form#navigation");
            jQuery.fn.extend({
                disable: function(state) {
                    return this.each(function() {
                        var $this = $(this);
                        $this.toggleClass('disabled', state);
                    });
                }
            });
            //$("#btnContinue").disable(true);
          $(document).on('change', '.myCheck', function(e){
            //console.log("changed");
              var $theRow = $(this).parent().parent();
              var can = $theRow.children(".can").text();
              var year = $theRow.children(".year").text();
              var month = $theRow.children(".month").text();
              var totals = $theRow.children(".totals").text().replace("$", "").replace(",", "");
              var action = ($(this).is(":checked")) ? "add" : "remove";
              var status = $theRow.children(".status");
              var lev = $theRow.children(".lev").text().replace("$", "").replace(",", "");
              var pen = $theRow.children(".pen").text().replace("$", "").replace(",", "");
              var minPay = parseFloat(Number(lev) + Number(pen)).toFixed(2);
              //console.log("minPay is " + minPay);
                  //status.fadeTo('slow', 1, function() {
                    // (action == "remove") 
                    //    ? status.html("removing").fadeIn("slow", function() {  /* animation complete*/  }).delay( 800 ).fadeOut("slow", function() { }) 
                    //    : status.html("adding").fadeIn("slow", function() {  /* animation complete*/ }).delay( 800 ).fadeOut("slow", function() { }) ;
                    (action == "remove") 
                        ? $(this).parent().animate({ backgroundColor: "#FDD9D9"}, 500 )
                        :  $(this).parent().animate({ backgroundColor: "#CBE9CB"}, 500 );
                  //});
              $("#btnContinue").disable(true);
                $.ajax({
                    type: "GET",
                    url: '_paymentsAjax.jsp',
                    data: { can: can, year: year, month: month, minPay: minPay, totals: totals, action: action },
                    contentType: "application/json; charset=utf-8",
                    success: successFunc,
                    error: errorFunc
                });
                function successFunc(data, status) {  $("#btnContinue").disable(false); }
                function errorFunc(data, status) { console.log('status: ' + status); }
              // $('#textbox1').val($(this).is(':checked'));        
          });



            $('#btnContinue').on('click', 'a.disabled', function(event) {
                event.preventDefault();
            });
            $(document).on("click", "#addToCart", function(e){
                window.location = "pay.jsp";
                //e.preventDefault();
                //e.stopPropagation();
                //var x = 0;                               
                //$('input[type="checkbox"]:checked').each(function() {x++;});
                //var months = $('input[type="checkbox"]:checked').map(function() {return this.value;}).get().join(',');
                ////console.log(months);
                //if(x > 0) $("#pay").submit(); else { $("#message").html("You must pick some months to pay &nbsp;&nbsp;"); }

            });
            $("table#recentsTable a").click(function(e) {
                e.preventDefault();
                e.stopPropagation();
                //console.log("clicked");
                var can = $(this).text();
                var name = $(this).parent().children("#sidebarRecent").text();
                //var theForm = $("form#navigation");
                $theForm.children("input#can").prop("value", can);
                $theForm.children("input#name").prop("value", name);
                $theForm.prop("action", "yearlySummary.jsp");
                $theForm.submit();
            });  
            $("#feedback a").click(function(e) {
                e.preventDefault();
                e.stopPropagation();
                //var theForm = $("form#navigation");
                $theForm.prop("method", "post");
                $theForm.prop("action", "feedback.jsp");
                $theForm.submit();
            });              

            $("#btnBack").on("click", function(e){
                e.preventDefault();
                e.stopPropagation();
                //console.log("clicked a tab");
                var goToPage = "<%= (isDefined(request.getParameter("current")) ? request.getParameter("current") : "dealerships.jsp") %>";
                goToPage = (goToPage == "pay.jsp" ? "dealerships.jsp" : goToPage);
                //var $theForm = $("form#navigation");
                $theForm.prop("action", goToPage);
                //$theForm.children("input#can").prop("value", can);
                //$theForm.children("input#year").prop("value", theYear);
                $theForm.submit();
            });
            $("#btnContinue").on("click", function(e){
                e.preventDefault();
                e.stopPropagation();
                console.log("clicked continue");
                
                $theForm.prop("action", "pay.jsp");
                $theForm.submit();
            });
        });
    </script>
</body>
</html>
