<%@ page import="java.lang.reflect.*,java.time.*,java.time.format.*" 
%><%@ include file="_configuration.inc"
%><%--


    Still need to address due-date and payment checkbox/link

    Need to add in retrieval into this page

    Need to add error page handling

--%><% 
    String pageTitle = "Dealer Inventory";

    // It appears we're using these values ONLY to pass to __getYearly.jsp - If they're session values why pass them???
    //String client_id = (String) session.getAttribute( "client_id");
    String userid = (String) session.getAttribute( "userid");

    String client_id            = sitAccount.getClientId();
    String clientId             = sitAccount.getClientId();

    boolean showWaccount = true;
    boolean showWyearSelect = true;
    boolean showWyearDisplay = false;
    boolean showWyearMonthDisplay = false;
    boolean showUpload = false;
    showLegend = true;
%><%@ include file="_top1.inc" %>
    <style>
        #body { top: 380px; }
        #bodyTop { height: 250px; margin-bottom: 0px; border-bottom: 1px solid #808080;}/**/
        #annual {margin: 10px 220px;}
        #note { text-align: center; color: red; font-style: italic; font-size: 15px; margin-top: 50px; }
    </style>

    <%@ include file="_top2.inc" %>
    <%= recents %>
    <%@ include file="_widgets.inc" %>
    <div style="clear:both;"></div>
        <button id="annual" class="btn btn-primary" style='margin-left: 320px;'>View Annual Declaration</button>
    </div><!-- #bodyTop -->

   <div id="body" >
        <style>
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
            #dataTable tbody#loading td div { text-align:center; height: 240px; padding-top: 100px; font-size: 18px; font-style:italic; background-color: darkgrey; }
        </style>
        <div id="myTableDiv">
            <table id=dataTable>
            <thead>
                <tr> <th> Month </th> <th> Due Date </th> <th> Inventory Sales </th>
                     <th> Levy Due </th> <th> Pen Due </th> <th> Fines Due </th> <th> NSF Due </th> <th> Total Due </th> 
                     <th> Submitted </th> <th> PYMT Posted </th> <th> Action </th> <th> Pay </th> 
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
                     <td> </td> <td> </td> <td> </td> <td> </td> <td> </td>
                     <th colspan=3></th><th> <button id=pay> Pay </button> </th>
                </tr>
            </tfoot>
            </table>
          <!--<div id="testDiv" style='margin-left: 60px;'></div>-->
        </div>
        <!--PRC 194603 Added note -->
        <div id="note">
            Note: Sales totals for all other sales types are shown on each month's statement page.
        </div>
    </div><!-- /body -->
    <div id="operationWarning" style="position: relative;">
        <div style="text-align: center; font-weight: bold;">
            <div style="color: red;">Warning!!</div><br>
            Attempted to perform an unauthorized operation.
        </div>
    </div>


    <form id="navigation" action="yearlySummary.jsp" method="post">
        <input type="hidden" name="can"   id="can"   value="<%= can %>">
        <input type="hidden" name="year"  id="year"  value="">
        <input type="hidden" name="client_id"  id="client_id"  value="<%= client_id %>">
        <input type="hidden" name="name"  id="name"  value="<%= request.getParameter("name") %>">
        <input type="hidden" name="totals" id="totals" value="">
        <input type="hidden" name="month" id="month" value="">
        <input type="hidden" name="current" id="current" value="<%= current_page %>">
        <input type="hidden" name="category"  id="category"  value="<%= category %>">
    </form>

<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script type="text/javascript" src="assets/js/sitcommon.js"></script>
    <script type="text/javascript" src="yearlySummary.js?<%= (new java.util.Date()).getTime() %>"></script>
        <script>
            $(function() 
                {
                    $.post( "yearlySummary_ws.jsp", { "can": $("#can").val() } )
                            .done(
                                function (data, status, jqxhr)
                                {
                                    console.log("Done response");
                                    console.log(data);
                                    try
                                    {
                                        yearlyData = JSON.parse(data);
                                        $("#yearSelect").change();
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
            function gotoSales()
            {
                $("#year").val($("#yearSelect").val());
                $("#month").val($(this).attr("id"));
                $("#navigation").attr("action","sales.jsp").submit();
            }

            function updateCart(event)
            {
                var action  = ($(this).is(":checked") ? "add" : "remove");
                var year    = $("#yearSelect").val();
                var month   = $(this).val();
                

                var record = yearlyData[year][month];

                var fine = record.mfineLevyBal.c$add(record.mfinePenBal);
                var nsf  = record.mnsfLevyBal.c$add(record.mnsfPenBal);
                var minPayment  = record.amountDue.c$subtract(fine).c$subtract(nsf);
                var totalPayment = record.amountDue;

                // Payment object stores month "as defined" but expands to 2-digits on remove
                month = (month < 10 ? "0" : "") + month;
                $.post( "_paymentsAjax.jsp",
                        { "can": $("#can").val(), "year": year, "month": month, "totals": totalPayment, "minPay": minPayment, "action": action }
                      )
                        .done(
                            function (data, status, jqxhr)
                            {
                                console.log("Done response");
                                console.log(data);
                            }
                        )
                        .fail(
                            function (data, status, jqxhr)
                            {
                                alert("Failed to update cart, processing error: ");
                                console.log($("#loginMessages .errors").html()+jqxhr.status);
                            }
                        )
                        .always(
                            function (data, status, jqxhr)
                            {
                            }
                        );
            }

/***************************************************
          $(document).on('change', 'input[type="checkbox"][name="payme"]', function(e){
            //console.log("changed");
              var theYear = $yearSelect.val();
              var can = "<%= can %>";
              var theMonth = $(this).val();
              var action = ($(this).is(":checked")) ? "add" : "remove";
              var totals = $(this).parents().children(".totalsForPay").val();
              var minPay = $(this).parents().children(".minPay").val();
              if ( false )
                  $.ajax({
                      type: "GET",
                      url: '_paymentsAjax.jsp',
                      data: { can: can, year: theYear, month:theMonth, minPay: minPay, totals: totals, action: action },
                              //can: can, year: year,    month: month,   minPay: minPay, totals: totals, action: action
                      contentType: "application/json; charset=utf-8",
                      success: successFunc,
                      error: errorFunc
                  });
//payments.remove(thiscan, thisyear, thismonth);
                  function successFunc(data, status) { console.log("data: " + data, "status: " + status); }
                  function errorFunc(data, status) { console.log('status: ' + status); }
              // $('#textbox1').val($(this).is(':checked'));        
          });
*****************************************/
            $(document).on('click', '#pay', function(e){
                  var viewOnly          = "<%= viewOnly %>";
                  if ("true" != viewOnly) {
                      e.preventDefault();
                      e.stopPropagation();
                      var can = "<%= can %>";
                      var theYear = $("#yearSelect").val();
                      var months = $('input[type="checkbox"][name="payme"]:checked').map(function () {
                          return this.value;
                      }).get().join(',');
                      var totals = $('input[type="checkbox"][name="payme"]:checked').map(function () {
                          return $(this).parents().children(".totalsForPay").val();
                      }).get().join(',');
                      var theForm = $("form#navigation");
                      var client_id = "<%= client_id %>";
                      theForm.children("input#can").prop("value", can);
                      theForm.children("input#month").prop("value", months);
                      theForm.children("input#totals").prop("value", totals);
                      theForm.children("input#year").prop("value", theYear);
                      theForm.children("input#client_id").prop("value", client_id);
                      theForm.prop("action", "pay.jsp");
                      console.log(totals);
                      //theForm.prop("action", "/act_webdev/_admin/listParams.jsp");
                      theForm.submit();
                  } else {
                      $("#operationWarning").dialog("open");
                  }
            });

        </script>
    <script>
      $(document).ready(function() {
          var $yearSelect = $("#yearSelect");
          updateYearly();                      // initial update on page load
          $yearSelect.change(updateYearly);    // updates on select

          $(document).on('change', 'input[type="checkbox"][name="payme"]', function(e){
            //console.log("changed");
              var theYear = $yearSelect.val();
              var can = "<%= can %>";
              var theMonth = $(this).val();
              var action = ($(this).is(":checked")) ? "add" : "remove";
              var totals = $(this).parents().children(".totalsForPay").val();
              var minPay = $(this).parents().children(".minPay").val();
              if ( false )
                  $.ajax({
                      type: "GET",
                      url: '_paymentsAjax.jsp',
                      data: { can: can, year: theYear, month:theMonth, minPay: minPay, totals: totals, action: action },
                              //can: can, year: year,    month: month,   minPay: minPay, totals: totals, action: action
                      contentType: "application/json; charset=utf-8",
                      success: successFunc,
                      error: errorFunc
                  });
//payments.remove(thiscan, thisyear, thismonth);
                  function successFunc(data, status) { console.log("data: " + data, "status: " + status); }
                  function errorFunc(data, status) { console.log('status: ' + status); }
              // $('#textbox1').val($(this).is(':checked'));        
          });

          function updateYearly() {
            if ( true ) return;
              $("#testDiv").html("<div style=\"font-size: 18px; margin-left: 310px; margin-top: 80px;\">Loading.....</div>");
              var theYear = $yearSelect.val();
              var can = "<%= can %>";
              var userid = "<%= userid %>";
              var client_id = "<%= client_id %>";
              var category = "<%= category %>";
			  // PRC 190387 set the flag if older than 2 years, the reports are only availabe for viewing
			  var viewFlag = false;
			  if( theYear < "<%= currentYear %>"-1 ){
				viewFlag = true;
			  }
			  
              if ( false )
              $.ajax({
                  type: "GET",
                  url: '__getYearly.jsp',
                  data: { can: can, year: theYear, client_id: client_id, userid: userid, category: category, viewFlag: viewFlag},
                  contentType: "application/json; charset=utf-8",
                  success: successFunc,
                  error: errorFunc
              });

              function successFunc(data, status) { setTimeout(function(){$("#testDiv").html(data); }, 1500); }
              function errorFunc(data, status) { alert('status: ' + status); }
          };//function updateYearly
    	  
    	   $(document).on('click', '#annual', function(e){
              var can = "<%= can %>";
              var theYear = $("#yearSelect").val();
              var theForm = $("form#navigation");
              theForm.children("input#can").prop("value", can);
              theForm.children("input#year").prop("value", theYear);
              theForm.prop("action", "annualDeclaration.jsp");
              theForm.submit();              
         });

          $(document).on('click', 'table#myTable a', function(e){
              e.preventDefault();
              e.stopPropagation();
              var can = "<%= can %>";
              var theYear = $("#yearSelect").val();
              var theMonth = $(this).prop("id");
              var theForm = $("form#navigation");
              theForm.children("input#can").prop("value", can);
              //theForm.children("input#name").prop("value", name);
              theForm.children("input#month").prop("value", theMonth);
              theForm.children("input#year").prop("value", theYear);
              theForm.prop("action", "sales.jsp");
              theForm.submit();
          }); 
          $(document).on('click', '#btnPay', function(e){
              e.preventDefault();
              e.stopPropagation();
              var can = "<%= can %>";
              var theYear = $("#yearSelect").val();
              var months = $('input[type="checkbox"][name="payme"]:checked').map(function() {return this.value;}).get().join(',');
              var totals = $('input[type="checkbox"][name="payme"]:checked').map(function() {return $(this).parents().children(".totalsForPay").val() ;}).get().join(',');
              var theForm = $("form#navigation");
              var client_id = "<%= client_id %>";
              theForm.children("input#can").prop("value", can);
              theForm.children("input#month").prop("value", months);
              theForm.children("input#totals").prop("value", totals);
              theForm.children("input#year").prop("value", theYear);
              theForm.children("input#client_id").prop("value", client_id);
              theForm.prop("action", "pay.jsp");
              console.log(totals);
              //theForm.prop("action", "/act_webdev/_admin/listParams.jsp");
              theForm.submit();
          }); 

          $("table#recentsTable a").click(function(e) {
              e.preventDefault();
              e.stopPropagation();
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
              var can = "<%= can %>";
              theForm.children("input#can").prop("value", can);
              theForm.prop("method", "post");
              theForm.prop("action", "feedback.jsp");
              theForm.submit();
          });              
          $("#payments a").click(function (e) {
              e.preventDefault();
              e.stopPropagation();
              //console.log("clicked a tab");
              var theYear = $yearSelect.val();
              var $theForm = $("form#navigation");
              $theForm.prop("action", "paymentsDue.jsp");
              $theForm.children("input#year").prop("value", theYear);
              $theForm.submit();
              // }
          });
          $("#cart a").click(function (e) {
              e.preventDefault();
              e.stopPropagation();
              //console.log("clicked a tab");
              var theYear = $yearSelect.val();
              var $theForm = $("form#navigation");
              $theForm.prop("action", "pay.jsp");
              $theForm.children("input#year").prop("value", theYear);
              $theForm.submit();
              // }
          });
          $("#operationWarning").dialog({
              autoOpen: false,
              open: function (event, ui) { $(".ui-widget-overlay").css({background: "#000", opacity: 0.7}) },
              modal:true,
              width:500,
              buttons:[
                  {
                      text:"OK",
                      click: function() { $(this).dialog("close");}
                  }
              ]
          });
      });
    </script>
    <script>
        var yearlyData = {};
    </script>
</body>
</html>
