<%@ include file="_configuration.inc"%>
<% 
    // general
    String pageTitle = categoryNomen + " Tax Statement - Page 2";
    String client_id = (String) session.getAttribute( "client_id");
    String userid = (String) session.getAttribute( "userid");
    boolean showWaccount = true;
    boolean showWyearSelect = false;
    boolean showWyearDisplay = false;
    boolean showWyearMonthDisplay = true;
    boolean showUpload = false;
    java.text.DecimalFormat df = new java.text.DecimalFormat("$###,###,###.00");
    StringBuffer sb = new StringBuffer();
    boolean isFinalized = false;
    String report_sequence = nvl(request.getParameter("report_seq"), "0");
    // totals
    String countDL = "";
    String countFL = "";
    String countMain = "";
    String countSS = "";
    String countRL = "";
    String amountDL = "";
    String amountFL = "";
    String amountMain = "";
    String amountSS = "";
    String amountRL = "";
    String pdf_url = "";

    String report_status = "";
    double timeDiff = 0.0;

    // database
    Connection connection = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    boolean inCart = (payments.isInCart(can, year, month));

%>
<%
if(request.getParameter("can") != null){
    connection = connect();
    try{    
 
        try { // Step #1 get the dealer info          
            ps = connection.prepareStatement("select count(can), to_char(sum(sales_price), '$999,999,999.00') amount, sale_type"
                                         + " from   sit_sales "
                                         + " where  can = ? and year=? and month=? and status <> 'D' and report_seq = ?"
                                         + " group by sale_type"
                                         + " order by sale_type");
            ps.setString(1, can);
            ps.setString(2, year);
            ps.setInt(3, Integer.parseInt(month));
            ps.setString(4, report_sequence);
            
            rs = ps.executeQuery();

            while (rs.next()){
                if("DL".equals(rs.getString(3))){
                    countDL = rs.getString(1);
                    amountDL = rs.getString(2);
                }else if("FL".equals(rs.getString(3))){
                    countFL = rs.getString(1);
                    amountFL = rs.getString(2);
                }else if(category.equals(rs.getString(3))){
                    countMain = rs.getString(1);
                    amountMain = rs.getString(2);
                }else if("SS".equals(rs.getString(3))){
                    countSS = rs.getString(1);
                    amountSS = rs.getString(2);
                }else if("RL".equals(rs.getString(3))){
                    countRL = rs.getString(1);
                    amountRL = rs.getString(2);
                }
            }// while
       } catch (Exception e) {
            SITLog.error(e, "\r\nProblem getting totals in confirmTotals.jsp\r\n");
       } finally {
           try { rs.close(); } catch (Exception e) { }
           rs = null;
           try { ps.close(); } catch (Exception e) { }
           ps = null;
       }// try get dealerships


        try { // check to see if this has been finalized
            ps = connection.prepareStatement("select report_status, (24 * (sysdate - finalize_date)) timeDiff from sit_sales_master "
                                           + "where client_id=? and can=? and year=? and month=? and report_seq = ?");                                           
            ps.setString(1, client_id);
            ps.setString(2, can);
            ps.setString(3, year);
            ps.setInt(4, Integer.parseInt(month));
            ps.setString(5, report_sequence);
            rs = ps.executeQuery();
            if (rs.next()){
                report_status = rs.getString(1);
                timeDiff = rs.getDouble(2);
                //isFinalized = rs.getInt(1) > 0;
            }
        } catch (Exception e) { 
            SITLog.error(e, "\r\nProblem getting count in confirmTotals.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        } // check to see if this has been finalized






    } catch (Exception e) {
    } finally {
        try { rs.close(); } catch (Exception e) { }
        rs = null;
        try { ps.close(); } catch (Exception e) { }
        ps = null;
        if (connection != null) {
            try { connection.close(); } catch (Exception e) { }
            connection = null;
        }
    }// outer try  

    if(request.getParameter("can") != null){
        boolean foundD = false;
        int i = 0;
        while ( !foundD && i < ds.size() ){
            d = (Dealership) ds.get(i);
            if (can.equals(d.can)) foundD = true; else i++;
        }
    }
}// if(request.getParameter("can") != null)
%>
<%@ include file="_viewForm.inc"%>
<%@ include file="_top1.inc" %>
<!-- include styles here -->
<style>
    .ui-datepicker-next,.ui-datepicker-prev{display:none;}
    #createSaleForm label { font-size: 11px;}
    #myTable tr th {text-align: right; padding-right: 10px; }
    #myTable tr td {text-align: right; padding-right: 10px; }
    #myTable tr td input {padding-left: 10px; text-align: right; }
</style>
<%@ include file="_top2.inc" %>
<%= recents %>
<%@ include file="_widgets.inc" %>
  </div> <!-- #bodyTop -->

   <div id="body" >
        <div id="myTableDiv">
            <div id="testDiv" name="testDiv"></div>
            <div id="formDiv" style="padding-bottom: 10px;">
                <button style="margin-left: 120px;" id="btnPrev" name="" class="btn btn-primary"><i class="fa fa-arrow-left"></i> Individual Sales</button>
                <form style="display: inline;" action="<%= pdf_url %>" target="_blank"><button style="margin-left: 40px;" id="btnViewForm" name="" 
                        <%= ("#".equals(pdf_url)) ? "class=\"btn btn-disabled\" disabled" : "class=\"btn btn-primary\"" %>>View Form</button></form>
                <button style="margin-left: 40px;" id="btnFinalize" name="btnFinalize" 
                        <%= ("C".equals(report_status)) ? "class=\"btn btn-disabled\" disabled" : "class=\"btn btn-primary\"" %>>Close Report</button>
            </div>
            <div id="cartWarning" style="display: none; background: yellow; margin: 10px 20px; padding: 10px; width: 700px; border: 1px solid black; font-weight: bold; text-align: center;">This item is currently in the cart. If you have made changes and want to proceed, click the "Close Report" button again and the item will be removed from the cart</div>
            <table id="myTable">
                <thead>
                    <tr><th colspan='2' style='text-align:left;'>Report# <%= report_sequence %></th></tr>
                    <tr>
                        <th>Breakdown of Sales (number of units sold)</th>
                        <th>Breakdown of Sales Amounts</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td nowrap>Net <%= categoryNomen %> Inventory <input type="text" disabled="true" id="" name="" style="width:40px; padding-right: 5px;" value="<%= nvl(countMain, "0") %>" /></td>
                        <td nowrap>Net <%= categoryNomen %> Inventory <input type="text" disabled="true" id="" name="" style="width:110px; padding-right: 5px;" value="<%= nvl(amountMain, "$0.00") %>" /></td>
                    </tr>
                    <% if ("MH".equals(category)) { %><!-- MH is the one with RL and no FL or DL -->
                        <tr>
                            <td>Retail Sales <input type="text" disabled="true" id="" name="" style="width:40px;padding-right: 5px;" value="<%= nvl(countRL, "0") %>" /></td>
                            <td>Retail Sales <input type="text" disabled="true" id="" name="" style="width:110px; padding-right: 5px;" value="<%= nvl(amountRL, "$0.00") %>" /></td>
                        </tr> 
                    <% } else { %>
                        <tr>
                            <td>Fleet Sales <input type="text" disabled="true" id="" name="" style="width:40px; padding-right: 5px;" value="<%= nvl(countFL, "0") %>" /></td>
                            <td>Fleet Sales <input type="text" disabled="true" id="" name="" style="width:110px; padding-right: 5px;" value="<%= nvl(amountFL, "$0.00") %>" /></td>
                        </tr> 
                        <tr>
                            <td>Dealer Sales <input type="text" disabled="true" id="" name="" style="width:40px; padding-right: 5px;" value="<%= nvl(countDL, "0") %>" /></td>
                            <td>Dealer Sales <input type="text" disabled="true" id="" name="" style="width:110px; padding-right: 5px;" value="<%= nvl(amountDL, "$0.00") %>" /></td>
                        </tr>
                    <% } %>
                    <tr>
                        <td>Subsequent Sales <input type="text" disabled="true" id="" name="" style="width:40px; padding-right: 5px;" value="<%= nvl(countSS, "0") %>" /></td>
                        <td>Subsequent Sales <input type="text" disabled="true" id="" name="" style="width:110px; padding-right: 5px;" value="<%= nvl(amountSS, "$0.00") %>" /></td>
                    </tr>
                </tbody>
            </table>     
        </div><!-- myTableDiv -->
		<br><br>
		<% if(client_id.equals("7580")){%>
		<div style="color: red;" align="center">
			<Strong><i>Note: All monthly statements and the annual declaration must also be submitted to Dallas Central Appraisal District.</i></Strong>
		</div>
		<% } %>
    </div><!-- /body -->
<div id="dialogWarning">
    <div style="text-align: center; font-weight: bold;">This payment is in progress. Please wait.<br>If there was a problem and you wish to proceed, this report will be reset.</div>
</div>
    <form id="navigation" action="yearlySummary.jsp" method="post">
        <input type="hidden" name="can" id="can" value="<%= can %>">
        <input type="hidden" name="name" id="name" value="<%= d.nameline1 %>">
        <input type="hidden" name="report_seq" id="report_seq" value="<%= report_sequence %>">
        <input type="hidden" name="year" id="year" value="<%= year %>">
        <input type="hidden" name="removeMe" id="removeMe" value="">
        <input type="hidden" name="month" id="month" value="<%= month %>">
        <input type="hidden" name="client_id" id="client_id" value="<%= client_id %>">
        <input type="hidden" name="category" id="category" value="<%= category %>">
        <input type="hidden" name="current" id="current" value="<%= current_page %>">
        <input type="hidden" name="bizStart" id="bizStart" value="<%= d.years[0] %>">
    </form>
   



<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script>
        $(document).ready(function() {
            var finalize_on_pay = ("<%= finalize_on_pay %>" === "true");
            var inCart          = ("<%= inCart %>" === "true");
            var report_status   = "<%= report_status %>";
            var timeDiff        = "<%= timeDiff %>";
            var pdf_url         = "<%= pdf_url %>";
            var myCounter = 0;
            var $dialogWarning = $("#dialogWarning");
            var cartCounter = 0;
            console.log("inCart? <%= inCart %>");
            console.log("report_status: " + report_status);
            console.log("timeDiff: " + timeDiff);
            console.log("pdf_url: " + pdf_url);
            console.log("finalize_on_pay: " + finalize_on_pay);
            $("#btnFinalize").click(function(e){
                e.preventDefault();
                e.stopPropagation();
                // if client pref, 
                //      when they hit "close report" check if item is in cart
                //             if so, popup saying item will be removed 
                var $theForm = $("form#navigation");
                
                if( finalize_on_pay && report_status == "I" && timeDiff < 1 && timeDiff > 0){
                        $dialogWarning.dialog( "open");
                } else if(finalize_on_pay && inCart && cartCounter == 0){
                    $("#cartWarning").show();
                    $theForm.children("#removeMe").prop("value", "yes");
                    cartCounter++;
                } else if(finalize_on_pay && inCart && myCounter == 0){
                    $("#cartWarning").show();
                    $theForm.children("#removeMe").prop("value", "yes");
                    myCounter++;
                }else{
                    $("#cartWarning").hide();
                    var can = "<%= can %>";
                    var year = "<%= year %>";
                    var month = "<%= month %>";
                    var form_name = "<%= form_name.replaceAll("[-]", "_") %>";
                    $theForm.children("#can").prop("value", can);
                    $theForm.children("#year").prop("value", year);
                    $theForm.children("#month").prop("value", month);
                    $theForm.children("#form_name").prop("value", form_name);
                    $theForm.prop("action", "forms/" + form_name + ".jsp"); 
                    $theForm.prop("method", "post");
                    $theForm.prop("target", "");
                    $theForm.submit();
                }
            });

            $("#btnPrev").click(function(e){
                e.preventDefault();
                e.stopPropagation();
                var can = "<%= can %>";
                var year = "<%= year %>";
                var month = "<%= month %>";
                var $theForm = $("form#navigation");
                $theForm.children("#can").prop("value", can);
                $theForm.children("#year").prop("value", year);
                $theForm.children("#month").prop("value", month);
                $theForm.prop("action", "sales.jsp");
                $theForm.prop("target", "");
                $theForm.prop("method", "post");
                $theForm.submit();
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
            function resetMe(){
                var client_id = "<%= client_id %>";
                var can = "<%= can %>";
                var year = "<%= year %>";
                var month = "<%= month %>";
                var report_seq = "<%= report_sequence %>";
                var action = "resetMe";
                jQuery.ajax({
                        url: '__writeInfo.jsp',
                        type: 'POST',
                        data: {can: can, client_id: client_id, year: year, month: month, action: action, report_seq:report_seq, removeMe: "yes"},
                        complete: function(xhr, textStatus) {
                          console.log(xhr.status);
                        },
                        success: function(data, textStatus, xhr) {
                        //console.log("can: "+can+", client_id: "+client_id+", year: "+year+", month: "+month+", action: "+action+", report_seq:"+report_seq);
                          report_status = "O";
                          console.log(xhr.status);
                          console.log("Success: " + data);
                         // updateYearly();
                        },
                        error:function(x,e) {
                            if (x.status == 0) {
                                alert('You are offline!!\n Please Check Your Network.');
                            } else if(x.status == 404) {
                                alert('Requested URL not found.');
                            } else if(x.status == 500) {
                                alert('Internel Server Error.');
                            } else if(e == 'parsererror') {
                                alert('Error.\nParsing JSON Request failed.');
                            } else if(e == 'timeout'){
                                alert('Request Time out.');
                            } else {
                                alert('Unknown Error.\n'+x.responseText);
                            }
                        }
                    });
                }            
            $dialogWarning.dialog({
                autoOpen: false,
                title: "Payment in Progress",
                open: function (event, ui) { $(".ui-widget-overlay").css({background: "#000", opacity: 0.7}) },
                modal: true,
                width: 750,
                buttons:[
                    {
                        text: "Do Not Proceed",
                        click: function() { $(this).dialog( "close" ); }
                    },
                    {
                        text: "Proceed: Reset Record",
                        click: function(){ 
                            resetMe();
                            inCart = false;
                            $(this).dialog( "close" );
                        }
                    } // button end
                ]  
                
            }); // end of dialog
            $("#payments a").click(function (e) {
                e.preventDefault();
                e.stopPropagation();
                var $theForm = $("form#navigation");
                var rs = $("#report_seq_dd").val();
                $theForm.prop("action", "paymentsDue.jsp");
                $theForm.children("input#report_seq").prop("value", rs);
                $theForm.submit();
              // }
            });            
        });//doc ready
    </script>
</body>
</html>