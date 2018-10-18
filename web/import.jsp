<%--
    DN - 03/23/2018 - PRC 195143
        - Added 2 more conditions for validateDate function
        - Dates of sales have to be in the range of the filing month and the filing year
    DN - 08/07/2018 - PRC 198408
        - Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
    DN - 08/21/2018 - PRC 194803
        - Updated sales type from "VTM" to "VM"
    DN - 09/05/2018 - PRC 204028
        - Replace "includes" with "indexOf"(IE does not support method "includes")
        - Do not calculate tax for sale types FL, DL, SS, RL
    DN - 09/12/2018 - PRC 197579
        - Updated code, the import request won't be executed if the users have the "view only" right
--%>
<%@ include file="_configuration.inc"%>
<% 
    String  pageTitle       = "File Import";
    StringBuffer sb         = new StringBuffer();
    String formatType       = "1";
    boolean defautFormat    = sitAccount.CSV_FILE_FORMAT_FOR_SIT_PORTAL;
    
    sb.append("starting<br>");
    
    boolean showWaccount             = true;
    boolean showWyearSelect          = false;
    boolean showWyearDisplay         = false;
    boolean showWyearMonthDisplay    = true;
    boolean showUpload               = false;
    boolean recordInserted           = false;
    String reportSequence            = nvl(request.getParameter("report_seq"), "1");
    
    if(request.getParameter("removeMe") != null 
        && "yes".equals(request.getParameter("removeMe"))){

        payments.remove(can, year, month);
    } 
    
    // figure out type of dealer
    if(can != null){ 
        boolean foundD = false;
        int i = 0;
        while ( !foundD && i < ds.size() ){
            d = (Dealership) ds.get(i);
            if (can.equals(d.can)) foundD = true; else i++;
        }
    }
    
    switch(d.dealerType){
        case 1:  category="MV";  //Motor Vehicle Inventory
                 break;
        case 2:  category="VM"; //Outboard
                 break;
        case 3:  category="HE";  //Heavy Equipment
                 break;
        case 4:  category="MH";  //Housing
                 break;
        default: category="MV";
                 break;
    }

    String              uptv        = "0.00000";
    SITSale             sitSale     =  SITSale.initialContext() ;

    try {   sitSale.setClientId(sitAccount.getClientId())
                    .setCan(can)
                    .setYear(year)
                    .getUptv(datasource);
        uptv = sitSale.uptv;

    } catch (Exception e){
        throw  e;
    }


%>

<%@ include file="_top1.inc" %>
<!-- include styles here -->
<style>
    #createSaleForm label { font-size: 11px; }
    #bodyTop { height: 300px; }
    #body { top: 380px;  border-top: 1px solid #808080; }
    #myTableDiv { margin-left: 20px;}
    #formDiv { padding-top: 170px; width:600px; }
    .error, .taxError { background-color: #FED0D0; }
    .errorText { color: red; }
    #myButton button { margin-top: 15px; display: none; }
    #submitError { display: inline-block; margin-left: 25px; color: #b70a0a; font-weight: bold; }
    th { padding: 8px; }

    input[type=text] { width: 100px; }
    input[type=text].error { background-color: pink; border-width: 1px; }

    #content table { border-spacing: 2px; border-collapse: separate; }
    #content table caption { font-weight: bold; font-size: 14px; margin: 10px; }
    #content table tr th { vertical-align:bottom; }

    #content table tr td:nth-child(1) input { text-align:center; }
    #content table tr td:nth-child(2) input { text-align:center; }
    #content table tr td:nth-child(6) input { text-align:center; }

    #content table tr td:nth-child(7) input { text-align:right; }
    #content table tr td:nth-child(8) input { text-align:right; }
    #content table tr td:nth-child(9) input { text-align:right; }

    #content table tr td:nth-child(1) { width: 80px; }
    #content table tr td:nth-child(2) { width: 50px; }
    #content table tr td:nth-child(3) { width: 150px; }
    #content table tr td:nth-child(4) { width: 150px; }
    #content table tr td:nth-child(5) { width: 150px; }
    #content table tr th:nth-child(6) { width: 50px;  }
    #content table tr td:nth-child(6) { width: 50px;  }
    #content table tr td:nth-child(7) { width: 100px; }
    #content table tr td:nth-child(8) { width: 80px; }
    #content table tr td:nth-child(9) { width: 80px; }
    #content table tr td input { width: 90%; padding: 2px 2px; }
    #content table tr td input:read-only { color: #464646; }

    #content table.nomodelyear tr td:nth-child(2) { display:none; }
    #content table.nomodelyear tr th:nth-child(2) { display:none; }

</style>
        <%@ include file="_top2.inc" %>
        <%= recents %>
        <%@ include file="_widgets.inc" %>

        <div id="formDiv">
            <button type="button" style="margin-left: 40px;"
                    id="btnPrev" name="btnPrev"
                    class="btn btn-primary"><i class="fa fa-arrow-left"></i> 
                    back to Sales
            </button>
        </div>

    </div> <!-- #bodyTop -->

    <div id="body" >
        <form id="navigation" method="post">
            <input type="hidden" name="client_id" id="client_id" value="<%= sitAccount.getClientId() %>">
            <input type="hidden" name="can" id="can" value="<%= can %>">
            <input type="hidden" name="year" id="year" value="<%= year %>">
            <input type="hidden" name="month" id="month" value="<%= month %>">
            <input type="hidden" name="report_seq" value="<%= reportSequence %>">
            <input type="hidden" name="current_page" id="current_page" value="<%= current_page %>">
        </form>
        <div id="importNotice" style=" display:none; height: 25px; padding-top: 3px; text-align: center; background-color: #c4cfdd "></div>
        <div id="myTableDiv">
            <h1>SIT Sales Importer</h1>
            <div>Select a comma-separated file:
                <input type="file" id="inputfile" name="inputfile" multiple="multiple">
            </div>
            <form  id="frmImport" method="post">
                 <div style="margin-top:50px;">
                    <pre><div id="content"></div></pre>
                </div>
                <div id="myButton">
                    <button
                            id ='btnSubmitImported'
                            name='btnSubmitImported'
                            class='btn btn-primary'>
                            Submit Records
                    </button>
                    <span id='submitError'></span>
                </div>
                <input type="hidden" name="client_id" value="<%= sitAccount.getClientId() %>">
                <input type="hidden" name="month" value="<%= month %>">
                <input type="hidden" name="year" value="<%= year %>">
                <input type="hidden" name="can" value="<%= can %>">
                <input type="hidden" name="report_seq" value="<%= reportSequence %>">
            </form>
        </div><!-- /myTableDiv -->
        <div id="operationWarning">
            <div style="text-align: center; font-weight: bold;">
                <div style="color: red;">Warning!!</div><br>
                Attempted to perform an unauthorized operation.
            </div>
        </div>
    </div><!-- /body -->


 
<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
<script src="assets/js/sitcommon.js"></script>
    <script>
    
    $(document).ready(function(){
        $("#inputfile").change(readCSVFile);
        submitRecords();
        goBack();


        var dealerType      = "<%= category %>";
        var taxRate         = "<%= uptv %>".c$valueOf();
        var defaultFormat   = <%= defautFormat %>;

        var firstRowHeader      =  !defaultFormat; // Based on client pref
        var swapSalesTypeColumn =  defaultFormat;    // Based on dealer type, HE dealers have switched columns

        var loadMonth = "<%= month %>".c$valueOf();
        var loadYear  = "<%= year %>".c$valueOf();
        var currentYear = (new Date()).getFullYear();

        var saleTypes = [ "MV", "FL", "DL", "SS", "VM", "HE", "MH", 'RL' ];

        var $operationWarning = $("#operationWarning");
        var viewOnly          = "<%= viewOnly %>"

        function readCSVFile()
        {   console.log( defaultFormat );
            var reader = new FileReader();
            reader.onload = function(e)
            {
                var records = reader.result.split(/\r?\n|\r/);
                if ( records.length == 0 )
                {
                    return;
                }

                // Check if first line is a header row
                var fields = records[0].split(",");
                if ( firstRowHeader )
                {
                    records.shift();
                    fields = records[0].split(",");
                }

                // Create the base table and headers
                var table = $("<table/>")
                    .append( $("<caption/>").html("Calculated tax is using tax factor of " + taxRate + " and will be used instead of Entered Tax value."))
                    .append( $("<tr/>")
                                //.append($("<th/>").html("Date<br>of Sale"))
                                .append($("<th/>").html("Sale Date"))
                                .append($("<th/>").html("Model<br>Year"))
                                .append($("<th/>").html("Make"))
                                .append($("<th/>").html("Identification<br>Number"))
                                .append($("<th/>").html("Purchaser"))
                                .append($("<th/>").html("Sale<br>Type"))
                                .append($("<th/>").html("Price"))
                                .append($("<th/>").html("Entered<br>Tax"))
                                .append($("<th/>").html("Calculated<br>Tax"))
                                );
                table.append( "<input type='hidden' name='inputDate' value='" + getCurrentDate() + "'>")


                // Process each record
                var line = 0;
                records.forEach(function(record)
                {
                    line++;

                    var fields = record.split(",");

                    // Probable blank line if only one field
                    if ( fields.length < 2 )
                    {
                        return;
                    }

                    // Adjust for Heavy Equipment record set to normalize our data.
                    // Heavy Equipment records exclude model year.
                    if ( fields.length == 7 )
                    {
                        fields.splice(fieldPosition.modelYear,0,"");
                    }

                    // Switch Sales Type and Purchaser Name fields if needed
                    // Heavy Equipment CSV import has Type and Purchaser fields switched.
                    if ( swapSalesTypeColumn )
                    {
                        fields.swap(fieldPosition.saleType,fieldPosition.saleType-1);
                    }

                    // Ignore records with an invalid number of fields...should we report error?
                    if ( fields.length != 8 )
                    {
                        return;
                    }

                    var row = $("<tr/>")
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"sale",  "value":fields[fieldPosition.saleDate]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"model",  "value":fields[fieldPosition.modelYear]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"make",  "value":fields[fieldPosition.modelMake]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"vin",   "value":fields[fieldPosition.vin]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"name",  "value":fields[fieldPosition.purchaserName]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"type",  "value":fields[fieldPosition.saleType]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"price", "value":fields[fieldPosition.salePrice]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"tax",   "value":fields[fieldPosition.taxAmount]})))
                                .append($("<td/>").append($("<input/>").attr({"type":"text", "name":"calculated", "value":"0"}).prop("readonly","readonly")))
                                ;

                    table.append(row);
                });


                // //////////////
                // Add change triggers on the data columns
                // //////////////

                // Sale Date
                $("tr td:first-child input",table).change(
                    function()
                    {
                        if ( isValidSaleDate($(this).val()) )
                        {
                            $(this).removeClass("error");
                        }
                        else
                        {
                            $(this).addClass("error");
                        }
                    }
                ).change();

                // Model Year
                $("tr td:nth-child(2) input",table).change(
                    function()
                    {
                        if ( isValidModelYear($(this).val()) )
                        {
                            $(this).removeClass("error");
                        }
                        else if ( dealerType != "HE")
                        {
                            $(this).addClass("error");
                        }
                    }
                ).change();

                // Sale Type
                $("tr td:nth-child(6) input",table).change(
                    function()
                    {
                        var saleType = $(this).val().toUpperCase();
                        if ( saleType == "VTM" )
                        {
                            saleType = "VM";
                        }

                        $(this).val(saleType);
                        if ( saleTypes.indexOf(saleType) > -1 )
                        {
                            $(this).removeClass("error");
                        }
                        else
                        {
                            $(this).addClass("error");
                        }
                    }
                ).change();

                // Sale Price
                $("tr td:nth-child(7) input",table).change(
                    function()
                    {
                        var amount = $(this).val().c$formatAsMoney();
                        $(this).val(amount);

                        // Since the calculated and entered tax amounts trigger off of each
                        // other to denote errors we'll need to trigger them in the following
                        // way. This ensures that the error indications are shown based on
                        // the current values and not because of a prior value.
                        $(this).parents("tr").find("input[name=calculated]").change();
                        $(this).parents("tr").find("input[name=tax]").change();
                        $(this).parents("tr").find("input[name=calculated]").change();
                    }
                ).change();

                // Calculated Tax
                $("tr td:nth-child(9) input",table).change(
                    function()
                    {
                        var price  = $(this).parents("tr").find("input[name=price]").val().c$valueOf();
                        var tax    = $(this).parents("tr").find("input[name=tax]").val().c$valueOf();
                        var amount = 0;
                        var saleType = $(this).parents("tr").find("input[name=type]").val().toUpperCase();
                        console.log(saleType);
                        // PRC 204028 do NOT calculate tax for sales type FL, DL, SS, RL
                        if (saleType != "FL"
                            && saleType != "DL"
                            && saleType != "SS"
                            && saleType != "RL"){

                            amount = (price * taxRate).c$toFixed(2);
                        }
                        $(this).val(amount.c$formatAsMoney());

                        if ( amount == tax )
                        {
                            $(this).removeClass("taxError");
                        }
                        else
                        {
                            $(this).addClass("taxError");
                        }
                    }
                ).change();

                // Entered Tax
                // Defined after calculated amount so it compares with the actual calculated amount
                $("tr td:nth-child(8) input",table).change(
                    function()
                    {
                        var taxAmount = $(this).val().c$valueOf();
                        $(this).val(taxAmount.c$formatAsMoney());

                        var calculatedAmountField = $(this).parents("tr").find("input[name=calculated]");
                        var calculatedAmount = calculatedAmountField.val().c$valueOf();
                        if ( taxAmount == calculatedAmount )
                        {
                            $(this).removeClass("taxError");
                        }
                        else
                        {
                            $(this).addClass("taxError");
                        }
                        calculatedAmountField.change();
                    }
                ).change();



                // Remove model year if dealer type doesn't have model years
                if ( dealerType == "HE" )
                {
                    table.addClass("nomodelyear");
                }

                // Display table for the user
                $("#content").append(table);
            }

            $("#content").html("");
            $("#submitError").html("");
            $("#btnSubmitImported").css("display","inline-block");
            reader.readAsText(document.getElementById("inputfile").files[0]);
        }

        // submit records to insert into table 'sit_sales'
        function submitRecords(){
            $("#btnSubmitImported").click(function(e){
                e.preventDefault();
                e.stopPropagation();

                if ("true" != viewOnly){
                    if ( $(".error").length == 0 ) {
                        $.ajax({
                            type:'POST',
                            url:'import_ws.jsp',
                            data:$("#frmImport").serialize(),
                            success: function(res){
                                console.log(res);
                                var result = JSON.parse(res);
                                console.log(result);
                                if ( result.importSalesRecordRequest == "success" ){
                                    if( result.data.importSalesRecord == "success" ) {
                                        $("#content").html("");
                                        $("#btnSubmitImported").css("display","none");
                                        $("#inputfile").val("");
                                    }
                                    $("#importNotice").css("display","block");
                                    $("#importNotice").html(result.data.detail);
                                } else {
                                    $("#importNotice").css("display","block");
                                    $("#importNotice").html(result.detail);
                                }
                            },
                            error: function(err){
                                $("#importNotice").css("display","block");
                                $("#importNotice").html(err);
                            }
                        })
                    } else {
                        $("#submitError").html("Please correct the problems above in red (you do not need to change the tax values)");
                    }
                } else {
                    $("#operationWarning").dialog("open");
                }
            })

        }

        // go back to sales page and reload the sales records
        function goBack(){
            $("#btnPrev").click(function(e){
                e.preventDefault();
                e.stopPropagation();
                $("#navigation").attr("action","sales.jsp");
                $("#navigation").submit();
            })
        }

        // These are the record field positions for
        // each value we are expecting
        var fieldPosition = {
                    saleDate:       0,
                    modelYear:      1,
                    modelMake:      2,
                    vin:            3,
                    purchaserName:  4,
                    saleType:       5,
                    salePrice:      6,
                    taxAmount:      7
                    };


        Array.prototype.swap = function (x,y) {
            var b = this[x];
            this[x] = this[y];
            this[y] = b;
            return this;
        }

        function isValidModelYear(year)
        {
            var date_regex = /^(19|20)\d{2}$/ ;
            if ( date_regex.test(year) )
            {
                if ( parseInt(year) <= currentYear+2 )
                {
                    return true;
                }
            }

            return false;
        }


        function getCurrentDate(){
                var d      = new Date();
                var month  = d.getMonth() + 1;
                var day    = d.getDate();
                var output = (('' + month).length < 2 ? '0' : '') + month + '/' +
                             (('' + day).length   < 2 ? '0' : '') + day + '/' + d.getFullYear();
                return output;
        }

        function isValidSaleDate(saleDate)
        {
            var date_regex = /^(0?[1-9]|1[0-2])\/(0?[1-9]|1\d|2\d|3[01])\/(19|20)\d{2}$/ ;
            if ( date_regex.test(saleDate) )
            {
                var testDate = new Date(saleDate);
                if ( testDate.getMonth()+1 == loadMonth && testDate.getFullYear() == loadYear )
                {
                    return true;
                }
            }

            return false;
        }

        $operationWarning.dialog({
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
</body>
</html>