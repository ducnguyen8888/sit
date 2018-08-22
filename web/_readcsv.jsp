
<%@ page import="act.sit.*" 
%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1.
    response.setHeader("Pragma", "no-cache");   // HTTP 1.0.
    response.setHeader("Expires", "0");         // Proxies.
    session.setMaxInactiveInterval(60*40);      // 40 minutes
%><!doctype html>
<html>
<head>
    <style>
        input[type=text] { width: 100px; }
        input[type=text].error { background-color: pink; }
    </style>
</head>
<body>

    <input type="file" id="inputfile" name="inputfile">

    <div style="margin-top:50px;">
    <pre><div id="content"></div>
    </pre>
    </div>

<script src="assets/js/jquery.min.js"></script> 
<script>
    (function(jquery) 
    { 
        jquery("#inputfile").change(readCSVFile);
    }
    )($);


    var ignoreFirstRow = false;
    var swapSalesTypeColumn = false;

    var saleTypes = [ "MV", "FL", "DL", "SS", "VTM", "HE", "MH" ];
    function readCSVFile()
    {
        var reader = new FileReader();
        reader.onload = function(e)
        {
            var records = reader.result.split(/\r?\n|\r/);
            if ( records.length == 0 )
            {
                console.log("Input file contained no records");
                return;
            }

            // Check if first line is a header row
            var fields = records[0].split(",");
            if ( ignoreFirstRow )
            {
                console.log("Skipping first record of file, determined to be header row");
                records.shift();
                fields = records[0].split(",");
            }


            // Switch Sales Type and Purchaser Name fields if needed
            // Heavy Equipment CSV import has Type and Purchaser fields switched.
            if ( swapSalesTypeColumn )
            {
                var offset = fields.length-8 + fieldPosition.saleType;
                console.log("Checking for field switch");
                console.log("       Offset: " + offset);
                console.log("        Field: " + fields[offset]);
                console.log("           +1: " + fields[offset+1]);
                console.log("        Check: " + ( ! (saleTypes.includes(fields[offset]) && fields[offset+1].indexOf(" ") > 0)));
                if (  ! (saleTypes.includes(fields[offset]) && fields[offset+1].indexOf(" ") > 0) )
                {
                    console.log("Sales type column is to be switched");
                    swapSalesTypeColumn = true;
                }
            }




            var salesRecords = [];

            var table = $("<table/>")
                .append( $("<tr/>")
                            .append($("<th/>").html("Date of Sale"))
                            .append($("<th/>").html("Model Year"))
                            .append($("<th/>").html("Make"))
                            .append($("<th/>").html("VIN"))
                            .append($("<th/>").html("Purchaser"))
                            .append($("<th/>").html("Sale Type"))
                            .append($("<th/>").html("Sale Price"))
                            .append($("<th/>").html("Tax Amount"))
                            .append($("<th/>").html("Calculated"))
                            );


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
                    fields.swap(fieldPosition.saleType,fieldPosition.saleType+1);
                }

                // Ignore records with an invalid number of fields...do we want to completely break?
                if ( fields.length != 8 )
                {
                    console.log("Line " + line + " had incorrect number of fields, skipping");
                    return;
                }

                console.log("Record: " + record);

                var sale = parseRecord(fields);
                var row = $("<tr/>")
                            .append($("<td/>").append(sale.saleDateInput))
                            .append($("<td/>").append(sale.modelYearInput))
                            .append($("<td/>").append(sale.modelMakeInput))
                            .append($("<td/>").append(sale.vinInput))
                            .append($("<td/>").append(sale.nameInput))
                            .append($("<td/>").append(sale.saleTypeInput))
                            .append($("<td/>").append(sale.salePriceInput))
                            .append($("<td/>").append(sale.taxAmountInput))
                            .append($("<td/>").html("$0.00"));

                table.append(row);
            });



            $("#content").html("Lines: " + records.length);
            $("#content").append(table);
        }
        console.log("\nFile: " + $("#inputfile").val() + "\n");
        reader.readAsText(document.getElementById("inputfile").files[0]);
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

    function parseRecord(fields) {
        var data = {};

        data.saleDate       = fields[fieldPosition.saleDate];
        data.saleDateInput  = createInputField("", "sale", data.saleDate, (isValidSaleDate(data.saleDate) ? "" : "error"));
        data.modelYear      = fields[fieldPosition.modelYear];
        data.modelYearInput  = createInputField("", "year", data.modelYear, "");
        data.modelMake      = fields[fieldPosition.modelMake];
        data.modelMakeInput  = createInputField("", "make", data.modelMake, "");
        data.vin            = fields[fieldPosition.vin];
        data.vinInput       = createInputField("", "vin", data.vin, "");
        data.name           = fields[fieldPosition.purchaserName];
        data.nameInput      = createInputField("", "name", data.name, "");
        data.saleType       = fields[fieldPosition.saleType];
        data.saleTypeInput  = createInputField("", "type", data.saleType, (saleTypes.includes(data.saleType) ? "" : "error"));
        data.salePrice      = fields[fieldPosition.salePrice];
        data.salePriceInput = createInputField("", "price", data.salePrice, "");
        data.taxAmount      = fields[fieldPosition.taxAmount];
        data.taxAmountInput = createInputField("", "tax", data.taxAmount, "");

        return data;
    }
    function createInputField(id, name, value, classNames)
    {
        return $("<input></input>").attr( { "type": "text", "id": id, "name": name, "value": value, "class": classNames } );
    }

    Array.prototype.swap = function (x,y) {
        var b = this[x];
        this[x] = this[y];
        this[y] = b;
        return this;
    }

    function isValidSaleDate(saleDate)
    {
        var date_regex = /^(0?[1-9]|1[0-2])\/(0?[1-9]|1\d|2\d|3[01])\/(19|20)\d{2}$/ ;
        if ( date_regex.test(saleDate) )
        {
            var testDate = new Date(saleDate);
            if ( testDate.getMonth()+1 == 2 && testDate.getFullyear == 2018 )
            {
                return true;
            }
        }

        return false;
    }
</script>

</body>
</html>
