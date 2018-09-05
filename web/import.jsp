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
--%>
<%@ include file="_configuration.inc"%>
<% 
    String  pageTitle   = "File Import";
    String  username    = (String) session.getAttribute( "username");
    String  client_id   = nvl(request.getParameter("client_id"), (String) session.getAttribute( "client_id"));
    month               = nvl(request.getParameter("month"), (String) session.getAttribute( "uMonth"));
    year                = nvl(request.getParameter("year"), (String) session.getAttribute( "uYear"));
    can                 = nvl(request.getParameter("can"), (String) session.getAttribute( "uCan"));
    StringBuffer sb     = new StringBuffer();
    String formatType   = "";
    SITUser    sitUser  = sitAccount.getUser();
    
    sb.append("starting<br>");
    
    boolean showWaccount             = true;
    boolean showWyearSelect          = false;
    boolean showWyearDisplay         = false;
    boolean showWyearMonthDisplay    = true;
    boolean showUpload               = false;
    boolean recordInserted           = false;
    String reportSequence            = nvl(request.getParameter("report_seq"), "0");
    
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



    // database
    Connection          connection  = null;
    PreparedStatement   ps          = null;
    ResultSet           rs          = null;
    String              uptv        = "0.00000";
    
    if(request.getParameter("can") != null){
        connection = connect();
        try{ // big outer
             // PRC 194803 use sit codeset "CSV_FILE_FORMAT_FOR_SIT_PORTAL" to control the import format
            formatType = nvl( getSitClientPref( connection, ps, rs, client_id, "CSV_FILE_FORMAT_FOR_SIT_PORTAL" ), "1");

            try {
            // note that Dawn and Fakhar said (1/5/2016) to use this function, which returns .002 for H00001 | 2013 | 79000000. 
            // What I was originally pulling was ~.197666 from the get_uptv function.
            // Not showing up for 2016 yet
                ps = connection.prepareStatement("SELECT act_subsystems.taxunit_monthly_rate(?,?,?) FROM DUAL");
                ps.setString(1, can);
                ps.setString(2, year);
                ps.setString(3, client_id);
                rs = ps.executeQuery();
                if(rs.next()) uptv = rs.getString(1); 
                sb.append("uptv is " + uptv + "<br>");
            } catch (Exception e) { 
                SITLog.error(e, "\r\nProblem getting tax rate in import.jsp\r\n");
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }// try get UPTV 
           
            if(isDefined(request.getParameter("calculated"))){
                int dealer_type = d.dealerType;

                String[] dos            = (isDefined(request.getParameter("sale"))) ? request.getParameterValues("sale")       
                                                                                    : new String[0];
                                                                                    
                String[] model          = (isDefined(request.getParameter("model")))? request.getParameterValues("model")     
                                                                                    : new String[0];
                                                                                    
                String[] make           = (isDefined(request.getParameter("make"))) ? request.getParameterValues("make")      
                                                                                    : new String[0];
                                                                                    
                String[] vin            = (isDefined(request.getParameter("vin")))  ? request.getParameterValues("vin")       
                                                                                    : new String[0];
                                                                                    
                String[] type           = (isDefined(request.getParameter("type"))) ? request.getParameterValues("type")      
                                                                                    : new String[0];
                                                                                    
                String[] purchaser      = (isDefined(request.getParameter("name"))) ? request.getParameterValues("name") 
                                                                                    : new String[0];
                                                                                    
                String[] price          = (isDefined(request.getParameter("price")))? request.getParameterValues("price")     
                                                                                    : new String[0];
                                                                                    
                String[] tax            = (isDefined(request.getParameter("tax")))  ? request.getParameterValues("tax")       
                                                                                    : new String[0];
                                                                                    
                String[] calculated     = (isDefined(request.getParameter("calculated")))? request.getParameterValues("calculated")   
                                                                                    : new String[0];
                                                                                    
                String inputDate        = (isDefined(request.getParameter("inputDate")))? request.getParameter("inputDate")   
                                                                                    : "01/01/1999";
                boolean report_seq_exists = false;
                String salesSeq = "0";
                // ************** NEW **************
                /* 
                    see if report seq is there for month/year/client/can
                        if not, get new value and create initialized record
                        if yes, get current value
                */

             

                //loop through each posted record => get new seq, write record
                for(int i = 0; i < dos.length; i++){
                    try { // get new salesSeq number
                        ps = connection.prepareStatement("select sit_sales_seq.nextval from dual");
                        rs = ps.executeQuery();
                        rs.next();
                        salesSeq = rs.getString(1);
                    } catch (Exception e) { sb.append("<br>Exception in executeUpdate area: " + e.toString() + "<br>");
                    } finally {
                        try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
                        rs = null;
                        try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
                        ps = null;
                    }// try get new salesSeq number    
                    try {
                        // PRC 198408 -  Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
                        ps = connection.prepareStatement("INSERT INTO sit_sales ("
                                                     + "    can, date_of_sale,"
                                                     + "    model_year, make,"
                                                     + "    vin_serial_no,"
                                                     + "    sale_type,"
                                                     + "    purchaser_name,"
                                                     + "    sales_price,"
                                                     + "    tax_amount,"
                                                     + "    client_id, "
                                                     + "    year, month,"
                                                     + "    sales_seq,"
                                                     + "    status,"
                                                     + "    report_seq,"
                                                     + "    uptv_factor,"
                                                     + "    pending_payment,"
                                                     + "    input_date,"
                                                     + "    opercode,"
                                                     + "    chngdate )"
                                                     + "  VALUES (?,TO_DATE(?, 'mm/dd/yyyy'),?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,TO_DATE(?, 'mm/dd/yyyy'), UPPER(?) , CURRENT_TIMESTAMP) ");
                        ps.setString(1, can);
                        ps.setString(2, dos[i]);//date_of_sale
                        ps.setString(3, (model.length > 0)?model[i]:null);//model_year
                        ps.setString(4, make[i]);//make
                        ps.setString(5, vin[i]);//vin_serial_no
                        ps.setString(6, type[i]);//sale_type
                        ps.setString(7, purchaser[i]);//purchaser
                        ps.setString(8, numberFormat( price[i] ));//sales_price
                        ps.setString(9,  numberFormat(calculated[i] ));//tax_amount
                        ps.setString(10, client_id);
                        ps.setString(11, year);
                        ps.setString(12, month);
                        ps.setString(13, salesSeq);
                        ps.setString(14, "O");//status
                        ps.setString(15, reportSequence);
                        ps.setString(16, uptv);
                        ps.setString(17, "Y");//pending_payment
                        ps.setString(18, inputDate);
                        ps.setString(19, sitUser.getUserName());

                        if (ps.executeUpdate() > 0){ //ps.executeUpdate()
                            recordInserted=true;
                            sb.append("insert success<br>");
                        } else {
                            sb.append("insert failure<br>");
                        }

                    } catch (Exception e) { sb.append("Exception in executeUpdate area: " + e.toString() + "<br>");
                    } finally {
                        try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
                        rs = null;
                        try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
                        ps = null;
                    }// try insert          
                    // ************** /NEW **************
                }//for(dos.length)
            }//if btnSubmitImported




        } catch (Exception e) {
          SITLog.error(e, "\r\nProblem in outer try in import.jsp\r\n");
          sb.append(e.toString() );
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
} // if isDefined(can)

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
            <input type="hidden" name="client_id" id="client_id" value="<%= client_id %>">
            <input type="hidden" name="can" id="can" value="<%= can %>">
            <input type="hidden" name="year" id="year" value="<%= year %>">
            <input type="hidden" name="month" id="month" value="<%= month %>">
            <input type="hidden" name="report_seq" value="<%= reportSequence %>">
            <input type="hidden" name="current_page" id="current_page" value="<%= current_page %>">
        </form>       
         <% if (recordInserted){ %>
        <div style="background: #c4cfdd; height: 25px; padding-top: 3px; text-align: center;">
            Your records were succesfully inserted. If you are finished, please click the "back to Sales" button above.
        </div>
        <% } %>
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
                <input type="hidden" name="client_id" value="<%= client_id %>">
                <input type="hidden" name="month" value="<%= month %>">
                <input type="hidden" name="year" value="<%= year %>">
                <input type="hidden" name="can" value="<%= can %>">
                <input type="hidden" name="report_seq" value="<%= reportSequence %>">
            </form>
        </div><!-- /myTableDiv -->
    </div><!-- /body -->


 
<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
<script src="assets/js/jquery.min.js"></script> 
<script src="assets/js/sitcommon.js"></script> 
    <script>
    
    $(document).ready(function(){
        $("#inputfile").change(readCSVFile);
        submitRecords();
        goBack();
    });


    var dealerType      = "<%= category %>";
    var taxRate         = "<%= uptv %>".c$valueOf();
    var defaultFormat   = "1" == "<%= formatType %>"

    var firstRowHeader      =  !defaultFormat; // Based on client pref
    var swapSalesTypeColumn =  defaultFormat;    // Based on dealer type, HE dealers have switched columns

    var loadMonth = "<%= month %>".c$valueOf();
    var loadYear  = "<%= year %>".c$valueOf();
    var currentYear = (new Date()).getFullYear();

    var saleTypes = [ "MV", "FL", "DL", "SS", "VM", "HE", "MH", 'RL' ];
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


            // Switch Sales Type and Purchaser Name fields if needed
            // Heavy Equipment CSV import has Type and Purchaser fields switched.
           // if ( swapSalesTypeColumn )
           // {
            //    var offset = fields.length-8 + fieldPosition.saleType;
             //   if (  ! (saleTypes.includes(fields[offset]) && fields[offset+1].indexOf(" ") > 0) )
             //   {
              //      swapSalesTypeColumn = true;
             //   }
           // }




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
        $("#btnSubmitImported").css("display","inline-block");
        reader.readAsText(document.getElementById("inputfile").files[0]);
    }
    
    // submit records to insert into table 'sit_sales'
    function submitRecords(){
        $("#btnSubmitImported").click(function(e){
            e.preventDefault();
            e.stopPropagation();
            if ( $(".error").length == 0 ) {
                $("#frmImport").attr("action","import.jsp");
                $("#frmImport").submit();
            } else {
                $("#submitError").html("Please correct the problems above in red (you do not need to change the tax values)");
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
</script>
</body>
</html>