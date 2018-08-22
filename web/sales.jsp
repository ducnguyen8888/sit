<%--
    DN - 02/12/2018- PRC 194602
        - apply to both of Dallas and Harris County
        - Created a web service page(getSaleTax.jsp) to calculate sales tax
        - Sales tax used to be calculated on front end, updated code to call a web service to calculate sales tax on back end.
    DN - 08/07/2018 - PRC 198408
        -Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
    DN - 08/21/2018 - PRC 194803
        - Updated sales type from "VTM" to "VM"

--%><%@ include file="_configuration.inc"%><%
    String      pageTitle   = categoryName + " Tax Statement";
    String      client_id   = (String) session.getAttribute( "client_id");
    String      userid      = (String) session.getAttribute( "userid");
    String      viewFlag    = (String) session.getAttribute( "viewFlag");
    
    SITUser     sitUser     = sitAccount.getUser();  



    boolean showWaccount = true;
    boolean showWyearSelect = false;
    boolean showWyearDisplay = false;
    boolean showWyearMonthDisplay = true;
    boolean showUpload = (!finalize_on_pay);
    boolean reportIsFinalized = false;
    java.text.DecimalFormat df = new java.text.DecimalFormat("$###,###,###.00");

    //int max_report_seq = 0; defined in configuration file


    report_seq = nvl(request.getParameter("report_seq"),1); // I need to create this for CREATE
    month = String.format("%02d",nvl(month,0)); // Make month always be 2-digits


    // Note: The original code opened a SQL connection that was outside of any control
    //       loop, because of this any exception that occurred between the time the
    //       connection was opened and closed caused the connection object to be lost.
    //       It's thought that this may be the cause of a persistant db pool leak.
    //       The immediate change made was to address this problem specifically. 
    //
    //       The original code also relied on everything working as expected. The CAN
    //       is expected to be passed in. The code attempted to match the CAN parameter
    //       with each dealership associated with this user. Because of the way the
    //       check was performed the last dealership was always defaulted to even if
    //       the CAN did not match. This would mean that any records created would
    //       probably be for the wrong dealership.
    //
    //       The matching dealership was assigned to the field "d", which is defined
    //       as a JavaBean in the _configuration.inc file. In the case where the CAN
    //       parameter was not provided the dealership would be the apparently empty
    //       dealership default from the JavaBean. The use of "d" as both a JavaBean
    //       and a local field is contrary to good coding practices, the JavaBean
    //       value is not being set or initialized. If it's purpose is to act as a
    //       local field then it should be defined as a local field, not a session bean.
    //
    //       Further review should be undertaken, when possible, to determine if the
    //       field usage and no-validation is a simple code-style issue, with no 
    //       impact on functionality or reliability, or if its symptomatic of further
    //       issues.


    // Did we fail to locate the dealer? This will occur if the CAN is not specified
    // or if the specified CAN did not match one of the associated dealerships.
    //
    // We'll default to returning the user to the main dealership page for now. 
    // We need to create an error page to handle issues like this.
    if ( dealership == null )
    {
        response.sendRedirect(request.getRequestURL().toString().replaceAll("^(.*)/[^/]*$","$1/dealerships.jsp"));
        return;
    }

    boolean isInCart = payments.isInCart(can, year, month);



    try ( Connection con = connect(); ) 
    {   // Retrieve max report sequence
        try ( PreparedStatement ps = con.prepareStatement(
                                          "select max(report_seq) as \"sequence\" "
                                        + "  from sit_sales_master "
                                        + " where client_id=? and year=? and can=? and month=?"
                                        );
                )
        {   ps.setString(1, client_id);
            ps.setString(2, year);
            ps.setString(3, can);
            ps.setString(4, month);
            try ( ResultSet rs = ps.executeQuery(); )
            {   max_report_seq = 0;
                if ( rs.next() )
                {   max_report_seq = rs.getInt("sequence");
                }
            }
        }

        // PRC 198408 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
        // If the record doesn't exist yet or this is an additional report we'll create the record
        if ( max_report_seq == 0 || "true".equals(request.getParameter("doAdditional")) )
        {   report_seq = ++max_report_seq;

            try ( PreparedStatement ps = con.prepareStatement(
                                              "insert into sit_sales_master ("
                                            + "     client_id,"
                                            + "     can,"
                                            + "     year,"
                                            + "     month,"
                                            + "     report_seq,"
                                            + "     dealer_type,"
                                            + "     form_name,"
                                            + "     report_status,"
                                            + "     pending_payment,"
                                            + "     opercode,"
                                            + "     chngdate "
                                            + " ) values ( "
                                            + "  ?, ?, ?, ?, "
                                            + "  ?, ?, ?, "
                                            + "  'O', 'N', UPPER(?), sysdate "
                                            + " )"
                                            );
                    )
            {   ps.setString(1, client_id);
                ps.setString(2, can);
                ps.setString(3, year);
                ps.setString(4, month);

                ps.setInt   (5, report_seq);
                ps.setInt   (6, dealership.dealerType);
                ps.setString(7, form_name);
                
                ps.setString(8, sitUser.getUserName() );

                ps.executeUpdate();
            }
            catch (Exception exception)
            {   SITLog.error(String.format("Exception creating sit_sales_master record (sales.jsp):\n%s\n",exception.toString()));
                SITLog.info(String.format("Client: (%s)  Can: (%s)  Year: (%s)  Month: (%s)  ReportSeq: %d  DealerType: %d  Form Name: (%s)\n",
                                            client_id, can, year, month, report_seq, 
                                            dealership.dealerType, form_name
                                            )
                                );

                // So we just ignore the exception? How does the user know there was a problem?
            }
        }
    }

   
%><%@ include file="_top1.inc" %>
<!-- include styles here -->
<style>
    .ui-datepicker-next,.ui-datepicker-prev{ display:none; }
    #createSaleForm label { font-size: 11px; }
    #bodyTop { height: 300px; }
    #body { top: 380px;  border-top: 1px solid #808080; }
    #formDiv { padding-top: 170px; width:800px; }
    #testDiv { margin-left: 70px;}
    #note { text-align: center; font-style: italic; font-size: 15px; margin-top: 50px;}
    #note span { color: red;  }
    .error { border: 1px solid red; }
    .errorText { color: red; }
        @media (max-width:1100px) { 
            #sidebarTitle { display: none; }
            #sideBar      { display: none; } 
            #body         { right: 0px; } 
            #bodyTop      { right: 0px; width: 100%; }
        }       
</style>
        <%@ include file="_top2.inc" %>
        <%= recents %>
        <%@ include file="_widgets.inc" %>

        <div id="formDiv">
            <button style="margin-left: 70px;" id="btnPrev" name="btnPrev" class="btn btn-primary"><i class="fa fa-arrow-left"></i> Yearly Summary</button>
            <button style="margin-left: 30px;" id="btnCreate" name="btnCreate" class="btn btn-primary">Create New Record</button>
            <button style="margin-left: 30px;" id="btnImport" name="btnImport" class="btn btn-primary">Import Records</button>
            <button style="margin-left: 30px;" id="btnNext" name="btnNext" class="btn btn-primary">Confirm Totals <i class="fa fa-arrow-right"></i></button>
        </div>

    </div> <!-- #bodyTop -->

   <div id="body" >
        <div id="myTableDiv">
            <div id="cartWarning" style="display: none; background: yellow; margin: 10px 130px; padding: 10px; width: 700px; border: 1px solid black;text-align: center;
    font-weight: bold;">This item is currently in the cart.<br>If you want to make changes, click the link or button again<br>and this item will be removed from the cart</div>
            <div id="testDiv"></div>
            <div id="note"><span>&#42;</span>Historical data not available</div>
        </div><!-- myTableDiv -->
    </div><!-- /body -->

    <form id="navigation" action="yearlySummary.jsp" method="post">
        <input type="hidden" id="can2"          name="can"              value="<%= dealership.can %>">
        <input type="hidden" id="name2"         name="name"             value="<%= dealership.nameline1 %>">
        <input type="hidden" id="year2"         name="year"             value="<%= year %>">
        <input type="hidden" id="report_seq"    name="report_seq"       value="<%= report_seq %>" >
        <input type="hidden" id="doAdditional"  name="doAdditional"     value="">
        <input type="hidden" id="month2"        name="month"            value="<%= month %>">
        <input type="hidden" id="removeMe2"     name="removeMe"         value="">
        <input type="hidden" id="current"       name="current"          value="<%= current_page %>">
        <input type="hidden" id="category"      name="category"         value="<%= category %>">
    </form>
    <div id="dialogWarning">
        <div style="text-align: center; font-weight: bold;">
            This payment is in progress. Please wait.<br>
            If there was a problem and you wish to proceed, this report will be reset.
        </div>
    </div>
    <div id="dialog">
        <form id="createSaleForm" action="__writeInfo.jsp" method="post"> <input style="height:0px; top:-1000px; position:absolute" type="text" value="">
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="DOS">Date of Sale</label><br>
                <input type="text" id="DOS" name="DOS" value="" style="width: 100px;" readonly='true'/>
            </div>
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="model" id="lblModel">Model Year</label><br>
                <input type="text" id="model" name="model" value="" placeholder="YYYY"/>
            </div>
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="make" id="lblMake">Make</label><br>
                <input type="text" id="make" name="make" value="" />
            </div>
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="vin" id="lblVIN">VIN</label><br>
                <input type="text" id="vin" name="vin" value="" />
            </div>
            <div style="clear: both;"></div>
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="purchaser">Purchaser Name</label><br>
                <input type="text" id="purchaser" name="purchaser" value="" />
            </div>
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="type">Sale Type</label><br>
                <select id="type" name="type">
                    <option value="<%= category %>">
                        <%
                            // PRC 194803 - 08/21/2018 - Updated sales type from "VTM" to "VM"
                            if ("MV".equals(category))  out.print("MV - Motor Vehicle Sales");
                            if ("HE".equals(category))  out.print("HE - Heavy Equipment Sales"); 
                            if ("MH".equals(category))  out.print("MH - Housing Sales"); 
                            if ("VM".equals(category))  out.print("VM - Outboard Sales");
                        %></option>
                    <% if ("MH".equals(category)){ %>
                        <option value="RL">RL - Retailer Sales</option>
                    <% } else { %>
                        <option value="FL">FL - Fleet Sales</option>
                        <option value="DL">DL - Dealer Sales</option>
                    <% } %>                    
                    <option value="SS">SS - Subsequent Sales</option>
                </select>
            </div>
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="price">Price</label><br>
                <input type="text" id="price" name="price" style="width: 100px;" value="" />
            </div>
            <div style="margin-top: 8px; margin-left: 11px; float:left;">
                <label for="tax">Tax</label><br>
                <input type="text" id="tax" name="tax" style="width: 100px;" value="" disabled readonly /><br>
            </div>
            <input type="hidden" id="action"      name="action"      value="" />
            <input type="hidden" id="client_id"   name="client_id"   value="<%= client_id %>" />
            <input type="hidden" id="can"         name="can"         value="<%= can %>" />
            <input type="hidden" id="year"        name="year"        value="<%= year %>" />
            <input type="hidden" id="month"       name="month"       value="<%= month %>" />
            <input type="hidden" id="sales_seq"   name="sales_seq"   value="" />
            <input type="hidden" id="report_seq"   name="report_seq"   value="<%= report_seq %>" />
            <input type="hidden" id="form_name"   name="form_name"   value="<%= form_name %>" />
            <input type="hidden" id="uptv_factor" name="uptv_factor" value="" />
            <input type="hidden" id="removeMe" name="removeMe" value="" />
        </form>
    </div>
<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script>
        $(document).ready(function() {

            var report_seq    = "<%= report_seq %>";
            var doAdditional  = false;
            var isFinalized   = false;
            var hasRecords    = false;
            var timeDiff     = 0.0;
            var finalizedDate = "";
            var report_status = "";
            var finalize_on_pay = ("<%= finalize_on_pay %>" === "true");
            var inCart = ("<%= isInCart %>" === "true");
            var cartCounter = 0;

            updateYearly();                         // initial update on page load
            <% if (showUpload) out.print("updateFileDownloads();"); %>
            
            //prevents "upload" button from being pushed if no file is added
            $('input:file').on("change", function() {
                $('#btnUpload').prop('disabled', !$(this).val()); 
            });

           <% if (showUpload){ %>
            function updateFileDownloads() {
                console.log("updating file downloads for " + report_seq);
                var client_id = "<%= client_id %>";
                var theYear   = "<%= year %>";
                var month     = "<%= month %>";
                var can       = "<%= can %>";
                $.ajax({
                    type: "GET",
                    url: '_getUploadedFiles.jsp',
                    data: {
                        client_id: client_id,
                        can: can,
                        year: theYear,
                        month: month, 
                        report_seq:report_seq
                    },
                    contentType: "application/json; charset=utf-8",
                    success: successFunc,
                    error: errorFunc
                });
                function successFunc(data, status) {
                   $(document).find("#fileInfo").html(data);
                   
                   //console.log(data);
                }
                function errorFunc(data, status) {
                    alert('status: ' + status);
                }
            }; //function updateFileDownloads
           <% } %> 
            function updateYearly() {
                console.log("report_seq: " + report_seq);
                $("#testDiv").html("<div style=\"font-size: 18px; margin-left: 310px; margin-top: 80px;\">Loading.....</div>");
                var client_id   = "<%= client_id %>";
                var can         = "<%= can %>";
                var theYear     = "<%= year %>";
                var month       = "<%= month %>";
                var userid      = "<%= userid %>";
                var category    = "<%= category %>";
                var form_name   = "<%= form_name %>";
                var dealer_type = "<%= dealership.dealerType %>";
                $.ajax({
                    type: "GET",
                    url: '__getStatement.jsp',
                    data: {
                        can: can,
                        year: theYear,
                        client_id: client_id,
                        userid: userid,
                        category: category,
                        month: month, 
                        form_name:form_name,
                        dealer_type:dealer_type, 
                        report_seq:report_seq
                    },
                    contentType: "application/json; charset=utf-8",
                    success: successFunc,
                    error: errorFunc,
                    complete: function(xhr,status) {
                       //console.log("isFinalized: " + isFinalized); inaccurate
                    }
                });
                function successFunc(data, status) {
                    setTimeout(function () {
                        $("#testDiv").html(data);
                        isFinalized    = ($(document).find("#status #isFinalized").val()   === "true"); // converts to actual boolean
                        hasRecords     = ($(document).find("#status #hasRecords").val()    === "true");
                        timeDiff      = $(document).find("#status #timeDiff").val();
                        finalizedDate  = $(document).find("#status #finalizedDate").val();
                        report_status  = $(document).find("#status #report_status").val();
                        // Don't allow additional reports until finalized or filedate exists && payment made in last hour
                        console.log("timeDiff: " + timeDiff);
                        console.log("finalize_on_pay: " + finalize_on_pay);
                        console.log("report_status: " + report_status);
                        console.log("isFinalized: " + isFinalized);
                        console.log("hasRecords: " + hasRecords);
                        console.log("finalizedDate: " + finalizedDate);
                        if(finalize_on_pay){
                            if (report_status == "C" || (report_status=='I' && timeDiff >= 1)){
                                $("#btnCreate").addClass("btn-disabled") // disable
                                               .removeClass("btn-primary")
                                               .prop("disabled", "true");
                                $("#btnImport").text("Create New Report");
                                // PRC 193081 Dallas  "Create New Report" option's only available for current year and prior year. The "Create New Report" button is disabled for older years
                                if("<%= viewFlag %>" ==  "true" && "<%= client_id %>" == "7580") {
                                    $("#btnImport").addClass("btn-disabled") // disable
                                                   .removeClass("btn-primary")
                                                   .prop("disabled", "true");
                                }
                                $("#upload_file").prop("disabled", "true");
                                doAdditional = true;
                            } else {
                                $("#btnCreate").addClass("btn-primary") // enable
                                               .removeClass("btn-disabled")
                                               .prop("disabled", "");
                                $("#btnImport").text("Import Records");
                                doAdditional = false;
                                $("#upload_file").prop("disabled", "");
                            }  



                        } else { 
                            if (isFinalized){
                                $("#btnCreate").addClass("btn-disabled") // disable
                                               .removeClass("btn-primary")
                                               .prop("disabled", "true");
                                $("#btnImport").text("Create New Report");
                                $("#upload_file").prop("disabled", "true");
                                doAdditional = true;
                            } else {
                                $("#btnCreate").addClass("btn-primary") // enable
                                               .removeClass("btn-disabled")
                                               .prop("disabled", "");
                                $("#btnImport").text("Import Records");
                                doAdditional = false;
                                $("#upload_file").prop("disabled", "");
                            }  
                        }
                    }, 1000);
                }
                function errorFunc(data, status) {
                    alert('status: ' + status);
                }
            }; //function updateYearly

            var mycounter = 0; // for span in .ui-dialog-buttonpane
            var $theForm = $("form#createSaleForm");
            var $theDialog = $("#dialog");
            $theDialog.hide();

            var $dialogWarning = $("#dialogWarning");

            var success = true;

            <% if (max_report_seq > 1){ %>
                $(document).on('change', '#report_seq_dd', function(e){ // edit link
                    report_seq = $("#report_seq_dd").val();
                    console.log("dd-report_seq: " + report_seq);
                    $("#frmUpload").prop("action", "file_upload.jsp?upload=Y&report_seq=" + report_seq);
                    console.log("frmUpload action is " + $("#frmUpload").prop("action"));
                    updateYearly();
                    <% if (showUpload) out.print("updateFileDownloads();"); %>
                });
            <% } %>

            $(document).on('click', '#myTable a', function(e){ // edit link
                e.preventDefault();
                e.stopPropagation();
                if( finalize_on_pay && report_status == "I" && timeDiff < 1 && timeDiff > 0){
                        $dialogWarning.dialog( "open");
                    } else if(finalize_on_pay && inCart && cartCounter == 0){
                    $("#cartWarning").show();
                    $theForm.children("#removeMe").prop("value", "yes");
                    cartCounter++;
                }else {
                    $("#cartWarning").hide();
                    $('.ui-dialog-buttonpane button:contains("Submit+")').button().hide();
                    if (mycounter === 0) { 
                        $(".ui-dialog-buttonpane").append("<span id=\"theError\" style=\"color: red;\"></span>"); 
                        mycounter += 1; 
                    }
                    var $theRow   = $(this).parent().parent();
                    var category  = "<%= category %>";
                    var seq       = $(this).prop("id"); // sales_seq
                    var dos       = $theRow.children(".dos").text();
                    var model     = $theRow.children(".model").text();
                    var make      = $theRow.children(".make").text();
                    var vin       = $theRow.children(".vin").text();
                    var type      = $theRow.children(".type").text();
                    var purchaser = $theRow.children(".purchaser").text();
                    var price     = ($theRow.children(".price").text()).replace(/[$,]/g,"");
                    var tax       = ($theRow.children(".tax").text()).replace(/[$,]/g,"");
                    var purpose = $(this).text();
                    $theForm.find("#DOS").prop("value",       dos       );
                    $theForm.find("#model").prop("value",     model     );
                    if (category === "HE") {
                        $theForm.find("#model").hide(); 
                        $theForm.find("#lblModel").hide();
                        $theForm.find("#lblMake").text("Item Name");
                        $theForm.find("#lblVIN").text("ID/Serial Number");
                    } 
                    if (category === "MH") {
                        $theForm.find("#lblVIN").text("Housing ID/Serial Number");
                    }
                    if (category === "VM") {
                        $theForm.find("#lblVIN").text("Identification Number");
                    }
                    $theForm.find("#make").prop("value",      make      );
                    $theForm.find("#vin").prop("value",       vin       );
                    $theForm.find("#type").prop("value",      type      );
                    $theForm.find("#purchaser").prop("value", purchaser );
                    $theForm.find("#price").prop("value",     price     );
                    $theForm.find("#tax").prop("value",       tax       );
                    $theForm.find("#sales_seq").prop("value", seq       );
                    $("#frmUPTV").text("uptv = " + $(document).find("#uptv").prop("value"));
                    console.log("purpose: " + purpose);
                    if(purpose === "edit"){
                        $theDialog.dialog( "option", "buttons", [
                                {
                                    text: "Cancel",
                                    click: function() { $(this).dialog( "close" ); cleanMe(); }
                                },
                                {
                                    text: "Finish",
                                    click: function(){ 
                                        writeMe();
                                        if (success)
                                            $(this).dialog( "close" ); 
                                    }
                                } // button end
                            ]  
                        );// buttons end                    
                        $theForm.children("#action").prop("value", "edit" );
                        $theDialog.dialog({title: "Modify Entry"});
                    } else {
                        $theDialog.dialog( "option", "buttons", [
                                {
                                    text: "Cancel",
                                    click: function() { $(this).dialog( "close" ); }
                                },
                                {
                                    text: "Delete",
                                    click: function(){ 
                                        writeMe();
                                        if (success)
                                            $(this).dialog( "close" ); 
                                    }
                                } // button end
                            ]  
                        );// buttons end
                        $theForm.children("#action").prop("value", "delete" );
                        $theDialog.dialog({title: "Delete Entry?"});
                    }
                    $theDialog.dialog( "open");
                    if (category === "HE") {
                        $theForm.find("#make").focus();
                    } else {
                        $theForm.find("#model").focus();
                    }
                }//cart check
            });

                $("button#btnCreate").click(function(e){ // new record
                    if( finalize_on_pay && report_status == "I" && timeDiff < 1 && timeDiff > 0){
                        $dialogWarning.dialog( "open");
                    } else if(finalize_on_pay && inCart && cartCounter == 0){
                        $("#cartWarning").show();
                        $theForm.children("#removeMe").prop("value", "yes");
                        cartCounter++;
                    } else {
                        $("#cartWarning").hide();                
                        $('.ui-dialog-buttonpane button:contains("Submit+")').button().show();
                        if (mycounter === 0) { 
                            $(".ui-dialog-buttonpane").append("<span id=\"theError\" style=\"color: red;\"></span>"); 
                            mycounter += 1; 
                        }
                        e.preventDefault();
                        e.stopPropagation();
                        var category  = "<%= category %>";
                        if (category === "HE") {
                            $theForm.find("#model").hide(); 
                            $theForm.find("#lblModel").hide();
                            $theForm.find("#lblMake").text("Item Name");
                            $theForm.find("#lblVIN").text("ID/Serial Number");
                        } 
                        if (category === "MH") {
                            $theForm.find("#lblVIN").text("Housing ID/Serial Number");
                        }
                        if (category === "VM") {
                            $theForm.find("#lblVIN").text("Identification Number");
                        }
                        var uptv =  $(document).find("#uptv").prop("value");
                        $("#frmUPTV").text("uptv = " + uptv);
                        $theForm.find("#type").get(0).selectedIndex = 0;
                        $theForm.find("#model").prop("value",     "" );
                        $theForm.find("#make").prop("value",      "" );
                        $theForm.find("#vin").prop("value",       "" );
                        $theForm.find("#purchaser").prop("value", "" );
                        $theForm.find("#price").prop("value",     "" );
                        $theForm.find("#tax").prop("value",       "" );
                        $theForm.children("#action").prop("value", "new");
                        $theDialog.dialog( "option", "buttons", [
                            {
                                text: "Add Another",
                                click: function(){
                                    writeMe();
                                    $theForm.find("#model").focus(); 
                                }
                            },
                            {
                                text: "Cancel",
                                click: function() { $(this).dialog( "close" ); cleanMe(); }
                            },
                            {
                                text: "Finish",
                                click: function(){ 
                                    writeMe();
                                    if (success)
                                        $(this).dialog( "close" ); 
                                }
                            } // button end
                        ]  );// buttons end                 
                        $theDialog.dialog({title: "Create Entry"});
                        $theDialog.dialog("open");
                        if (category === "HE") {
                            $theForm.find("#make").focus();
                        } else {
                            $theForm.find("#model").focus();
                        }
                    } // cart check
                });
            $("#price").on("blur", function(){ $.fn.setTax(); });
            $("#type").on("change", function(){ $.fn.setTax(); });

            // PRC 194602 call a web service to calculate sales tax
            $.fn.setTax = function() {
                var $price = $("#price");
                var type = $("#type").val();
                var $tax = $("#tax");
                var price = parseFloat($price.prop("value").replace(/[$,]/g,"")).toFixed(2);
                $.ajax({
                    type:'POST',
                    url: "getSaleTax.jsp",
                    data:{clientId:"<%= client_id %>",
                            can: "<%= can %>",
                            year: "<%= year%>",
                            sales: price,
                            type: type
                            },
                    success: function(res) {
                        try {
                            var status = JSON.parse(res);
                            if ( status.sendRequest == "success"
                               && status.data.calculateSalesTax == "success") {
                                $tax.prop("value",parseFloat(status.data.tax).toFixed(2));
                            } else if ( status.sendRequest == "success"
                               && status.data.calculateSalesTax == "failure") {
                                $tax.prop("value", parseFloat(status.tax).toFixed(2));
                                console.log(status.detail);
                            } else {
                                $tax.prop("value",parseFloat(status.tax).toFixed(2));
                                console.log(status.detail);
                            }
                        } catch (err){
                            console.log(err);
                        }
                    },
                    error: function(err){
                        console.log(err);
                    }
                });
                //var uptv = ( type=="MV" || type=="HE" || type=="MH" || type=="VTM" ) ? $(document).find("#uptv").prop("value") : "0.00";
                //var theTotal = (price * uptv).toFixed(2);
                //if($.isNumeric(price)){
                  //  $tax.prop("value", theTotal);
                  //  $price.prop("value", price);
                   // $("#frmUPTV").text( price + "*" + uptv + "=" + theTotal);
                //}
            }

            $("button#btnPrev").click(function(e){ // previous
                e.preventDefault();
                e.stopPropagation();
                var can = "<%= can %>";
                var year = "<%= year %>";
                var theForm = $("form#navigation");
                theForm.children("#can2").prop("value", can);
                theForm.children("#year2").prop("value", year);
                theForm.prop("action", "yearlySummary.jsp");
                theForm.submit();
            });
            $("button#btnImport").click(function(e){ // previous
                e.preventDefault();
                e.stopPropagation();
                console.log("clicked import");
               if( finalize_on_pay && report_status == "I" && timeDiff < 1 && timeDiff > 0){
                        $dialogWarning.dialog( "open");
                    } else  if(finalize_on_pay && inCart && cartCounter == 0){
                    $("#cartWarning").show();
                    $("form#navigation").children("#removeMe2").prop("value", "yes");
                    cartCounter++;
                    console.log("CartCounter: " + cartCounter);
                }else {
                    $("#cartWarning").hide();  
                    var can = "<%= can %>";
                    var year = "<%= year %>";
                    var month = "<%= month %>";
                    var theForm = $("form#navigation");
                    theForm.children("#report_seq").prop("value", report_seq);
                    theForm.children("#can2").prop("value", can);
                    theForm.children("#year2").prop("value", year);
                    theForm.children("#month2").prop("value", month);
                    theForm.children("#doAdditional").prop("value", doAdditional);
                    if(doAdditional){
                        //submit here and increment report_seq
                        theForm.prop("action", "sales.jsp");
                    }else{
                        theForm.prop("action", "import.jsp");
                    }
                    theForm.submit();
                }
            });

            $("button#btnNext").click(function(e){ // next
                e.preventDefault();
                e.stopPropagation();
                var can = "<%= can %>";
                var year = "<%= year %>";
                var month = "<%= month %>";
                var theForm = $("form#navigation");
                theForm.children("#report_seq").prop("value", report_seq);
                theForm.children("input#can2").prop("value", can);
                theForm.children("input#year2").prop("value", year);
                theForm.children("input#month2").prop("value", month);
                theForm.prop("action", "confirmTotals.jsp");
                theForm.submit();
            });

            $("table#recentsTable a").click(function(e) { // recents
                e.preventDefault();
                e.stopPropagation();
                var can = $(this).text();
                var name = $(this).parent().children("#sidebarRecent").text();
                var theForm = $("form#navigation");
                theForm.children("input#can2").prop("value", can);
                theForm.children("input#name2").prop("value", name);
                theForm.prop("action", "yearlySummary.jsp");
                theForm.submit();
            }); 
            
            $theDialog.dialog({
                autoOpen: false,
                //title: "Create new entry?",
                open: function (event, ui) { $(".ui-widget-overlay").css({background: "#000", opacity: 0.7}) },
                modal: true,
                width: 750
                
            }); // end of dialog
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
                            if (success){
                                inCart = false;
                                $(this).dialog( "close" );
                            }
                        }
                    } // button end
                ]  
                
            }); // end of dialog

       
             
            
            //$dialogWarning.show();


            function cleanMe(){
                $theForm.find("#model").prop("value", "").removeClass('error');
                $theForm.find("#make").prop("value", "").removeClass('error');
                $theForm.find("#vin").prop("value", "").removeClass('error');
                $theForm.find("#purchaser").prop("value", "").removeClass('error');
                $theForm.find("#price").prop("value", "").removeClass('error');
                $theForm.find("#tax").prop("value", "").removeClass('error');  

                $theForm.find("#lblModel").removeClass('errorText');
                $theForm.find("#lblMake").removeClass('errorText');
                $theForm.find("#lblVin").removeClass('errorText');
                $theForm.find("#lblPurchaser").removeClass('errorText');
                $theForm.find("#lblPrice").removeClass('errorText');
                $theForm.find("#lblTax").removeClass('errorText');                                
            }
            function resetMe(){
                var client_id = "<%= client_id %>";
                var can = "<%= can %>";
                var year = "<%= year %>";
                var month = "<%= month %>";
                var report_seq = "<%= report_seq %>";
                var action = "resetMe";
                jQuery.ajax({
                    url: '__writeInfo.jsp',
                    type: 'POST',
                    data: {can: can, client_id: client_id, year: year, month: month, action: action, report_seq:report_seq, removeMe: "yes"},
                    complete: function(xhr, textStatus) {
                      console.log(xhr.status);
                    },
                    success: function(data, textStatus, xhr) {
                      console.log(xhr.status);
                      console.log("Success: " + data);
                      updateYearly();
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



            
            function writeMe(){
                var category        = "<%= category %>";
                var action          = $theForm.find("#action").prop("value");
                var can             = $theForm.find("#can").prop("value");
                var date_of_sale    = $theForm.find("#DOS").prop("value");
                var model_year      = $theForm.find("#model").prop("value");
                var make            = $theForm.find("#make").prop("value");
                var vin_serial_no   = $theForm.find("#vin").prop("value");
                var sale_type       = $theForm.find("#type").prop("value");
                var purchaser_name  = $theForm.find("#purchaser").prop("value");
                var sales_price     = $theForm.find("#price").prop("value");
                var tax_amount      = $theForm.find("#tax").prop("value");
                var client_id       = $theForm.find("#client_id").prop("value");
                var year            = $theForm.find("#year").prop("value");
                var month           = $theForm.find("#month").prop("value");
                var form_name       = $theForm.find("#form_name").prop("value");
                var sales_seq       = $theForm.find("#sales_seq").prop("value");
                var removeMe        = $theForm.find("#removeMe").prop("value");
                var uptv_factor     = $(document).find("#uptv").prop("value");
                var pending_payment = "Y";
                var dealer_type     = "<%= dealership.dealerType %>";
                var input_date      = getCurrentDate();
                var status          = "O";
                if(action != "delete" && !filledOut(category)){
                    console.log("failed validation");
                } else { 
                    jQuery.ajax({
                        url: '__writeInfo.jsp',
                        type: 'POST',
                        data: {can: can, date_of_sale: date_of_sale, model_year: model_year, make: make, vin_serial_no: vin_serial_no, 
                               sale_type: sale_type, purchaser_name: purchaser_name, sales_price: sales_price, tax_amount: tax_amount, client_id: client_id, 
                               year: year, month: month, form_name: form_name, sales_seq: sales_seq, uptv_factor: uptv_factor, pending_payment: pending_payment, 
                               input_date: input_date, status: status, action: action, dealer_type: dealer_type,removeMe:removeMe, report_seq:report_seq},
                        complete: function(xhr, textStatus) {
                          console.log(xhr.status);
                        },
                        success: function(data, textStatus, xhr) {
                          console.log(xhr.status);
                          console.log("Success: " + data);
                          updateYearly();
                          cleanMe();
                          $("form#createSaleForm").children("#removeMe").prop("value", "");
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
            } //click

            $(function () {
                var date = new Date();
                var month = <%= month %> -1;
                var year = <%= year %>;
                date.setFullYear(year, month, 1);
                $("#DOS").datepicker({
                    onSelect: function() {
                      this.lastShown = new Date().getTime();
                   <%
                        if ("HE".equals(category))
                            out.print("$(document).find('#make').focus();");
                        else
                            out.print("$(document).find('#model').focus();");
                    %>
                    },
                    beforeShow: function() {
                      var time = new Date().getTime();
                      return this.lastShown === undefined || time - this.lastShown > 500;
                    },                    
                    changeMonth: false,
                    changeYear: false,
                    dateFormat: 'mm/dd/yy',
                    duration: 'fast',
                    stepMonths: 0
                })
                    .datepicker("setDate", date)
                    .datepicker("option", "hideIfNoPrevNext", true)
                    .datepicker("option", "autoOpen", false);
            });

            function filledOut(category){
                var $model     = $theForm.find("#model");
                var $make      = $theForm.find("#make");
                var $vin       = $theForm.find("#vin");
                var $type      = $theForm.find("#type");
                var $purchaser = $theForm.find("#purchaser");
                var $price     = $theForm.find("#price");
                var $tax       = $theForm.find("#tax");
                var $theError  = $(document).find("span#theError");
                if ((!$model.prop("value") || !$.isNumeric($model.prop("value")) || $model.prop("value").length != 4) && category != "HE" ) { 
                    console.log("in error area. Category is " + category);
                    $model.addClass('error'); 
                    $model.parent().find("label").addClass('errorText');
                    if (!$model.prop("value")){
                        $theError.text("value required");
                    } else if (!$.isNumeric($model.prop("value")) || $model.prop("value").length != 4 ){
                        $theError.text("Four numbers required");
                    } 
                    $model.focus();
                    success = false;
                    return false; 
                } else { 
                    $model.removeClass('error'); 
                    $model.parent().find("label").removeClass('errorText');
                    $theError.text("value required");
                }
                if (!$make.prop("value") ) { //&& category != "HE"
                    $make.addClass('error'); 
                    $make.parent().find("label").addClass('errorText');
                    $theError.text("value required");
                    $make.focus();
                    success = false;
                    return false; 
                } else { 
                    $make.removeClass('error'); 
                    $make.parent().find("label").removeClass('errorText');
                }
                if (!$vin.prop("value")) { 
                    $vin.addClass('error'); 
                    $vin.parent().find("label").addClass('errorText');
                    $theError.text("value required");
                    success = false;
                    return false; 
                } else { 
                    $vin.removeClass('error'); 
                    $vin.parent().find("label").removeClass('errorText');
                }
                if (!$type.prop("value")) { 
                    $type.addClass('error'); 
                    $type.parent().find("label").addClass('errorText');
                    $theError.text("value required");
                    success = false;
                    return false; 
                } else { 
                    $type.removeClass('error'); 
                    $type.parent().find("label").removeClass('errorText');
                }
                if (!$purchaser.prop("value")) { 
                    $purchaser.addClass('error'); 
                    $purchaser.parent().find("label").addClass('errorText');
                    $theError.text("value required");
                    success = false;
                    return false; 
                } else { 
                    $purchaser.removeClass('error'); 
                    $purchaser.parent().find("label").removeClass('errorText');
                }
                if (!$price.prop("value") || !$.isNumeric($price.prop("value")) ) { 
                    $price.addClass('error'); 
                    $price.parent().find("label").addClass('errorText');
                    $theError.text("value required");
                    success = false;
                    return false; 
                } else { 
                    $price.removeClass('error'); 
                    $price.parent().find("label").removeClass('errorText');
                }
                if (!$tax.prop("value") || !$.isNumeric($tax.prop("value")) ) { 
                    $tax.addClass('error'); 
                    $tax.parent().find("label").addClass('errorText');
                    $theError.text("value required");
                    success = false;
                    return false; 
                } else { 
                    $tax.removeClass('error'); 
                    $tax.parent().find("label").removeClass('errorText');
                }
                $theError.text("");
                success = true;
                return true;
            }
            
            function getCurrentDate(){
                var d      = new Date();
                var month  = d.getMonth() + 1;
                var day    = d.getDate();
                var output = (('' + month).length < 2 ? '0' : '') + month + '/' + 
                             (('' + day).length   < 2 ? '0' : '') + day + '/' + d.getFullYear();
                return output;
            }

            $("#feedback a").click(function(e) {
                e.preventDefault();
                e.stopPropagation();
                var theForm = $("form#navigation");
                var can = "<%= can %>";
                theForm.children("input#can2").prop("value", can);
                theForm.prop("method", "post");
                theForm.prop("action", "feedback.jsp");
                theForm.submit();
            });                 
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
          $("#cart a").click(function (e) {
                e.preventDefault();
                e.stopPropagation();
                var $theForm = $("form#navigation");
                var rs = $("#report_seq_dd").val();
                $theForm.prop("action", "pay.jsp");
                $theForm.children("input#report_seq").prop("value", rs);
                $theForm.submit();
              // }
          });          
      });//doc ready
    </script>
</body>
</html>
