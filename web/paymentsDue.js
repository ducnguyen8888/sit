    var monthNames = [ "", "January", "February", "March", "April", "May", "June",
                            "July", "August", "September", "October", "November", "December"
                        ];

    var emptyCell = $("<td/>").html("&nbsp;");

    var paymentCell   = $("<td/>").append($("<input/>").attr({"type": "checkbox", "name": "payme"}));

    function displayPaymentsDue()
    {
        var paymentsDue = window.paymentsDue;
        if ( ! paymentsDue ) 
        {
            console.log("Failed to locate payment due data");
            return;
        }
        if ( paymentsDue.length == 0 ) 
        {
            $("#dataTable tbody tr:first-child td div").html("This dealership has no payments available to pay");
            console.log("No payment due records, 0 length");
            return;
        }

        var currentYear = (new Date()).getFullYear();
        var currentMonth = (new Date()).getMonth()+1;

        var totals = {
                    sales:   0,
                    levy:    0,
                    penalty: 0,
                    fines:   0,
                    nsf:     0,
                    total:   0
                        };

        var header = $("#myTableDiv thead").children();
        $("#myTableDiv thead").remove();

        var bodyBlocks = [];
        var records = $("<tbody/>");

        for ( var idx=0; idx < paymentsDue.length; idx++ )
        {
            var dealer = paymentsDue[idx].dealer;
            var yearsDue = paymentsDue[idx].paymentsDue;


            // Add the Dealer ID row, name - can
            records = $("<tbody/>");
            var row = $("<tr/>");
            row.append( $("<td/>").attr("colspan","9")
                                  .attr("style","background-color: #b0b0b0;")
                                  .html(dealer.nameline1 + " - " + dealer.can));
            records.append(row);

            // Add descriptive header row
            records.append(header.clone());



            for ( var year in yearsDue ) 
            {
                var yearData = yearsDue[year];
                for ( var month in yearData )
                {
                    var monthData = yearData[month];
                    var row = $("<tr/>");
                    row.append($("<td/>").html(year))
                        .append($("<td/>").html(monthNames[month]))
                        .append($("<td/>").html(monthData.msaleLevyBal.c$formatAsMoney()))
                        .append($("<td/>").html(monthData.msalePenBal.c$formatAsMoney()))
                        .append($("<td/>").html((monthData.mfineLevyBal.c$add(monthData.mfinePenBal).c$formatAsMoney())))
                        .append($("<td/>").html((monthData.mnsfLevyBal.c$add(monthData.mnsfPenBal).c$formatAsMoney())))
                        .append($("<td/>").html(monthData.amountDue.c$formatAsMoney()));

                    // Payment
                    var cell = paymentCell.clone();
                    cell.find("input[type=checkbox]").attr("value",dealer.can + "|" + year + "|" + month);
                    row.append(cell);
                    if ( monthData.isInCart )
                    {
                        cell.find("input[type=checkbox]").prop("checked","checked");
                    }

                    records.append(row);


                    totals.sales    = totals.sales.c$add(monthData.salesPrice);
                    totals.levy     = totals.levy.c$add(monthData.msaleLevyBal);
                    totals.penalty  = totals.penalty.c$add(monthData.msalePenBal);
                    totals.fines    = totals.fines.c$add(monthData.mfineLevyBal);
                    totals.nsf      = totals.nsf.c$add(monthData.mnsfLevyBal);
                    totals.total    = totals.total.c$add(monthData.amountDue);
                }
            }

            // Add a separating row - helps to separate dealerships from one another
            row = $("<tr/>");
            row.append( $("<td/>").attr("colspan","9")
                                  .html(""));
            records.append(row);


            bodyBlocks.push(records);
        }
        $("#dataTable tbody, #dataTable tfoot").remove();

        $("#dataTable").append(bodyBlocks);
        $("#dataTable tbody input[type=checkbox]").change(updateCart);
        $("#dataTable tfoot tr td").remove();

        // Must be added in reverse order
        $("#dataTable tfoot tr th:first-child")
                                .after($("<td/>").html(totals.total.c$formatAsMoney()))
                                .after($("<td/>").html(totals.nsf.c$formatAsMoney()))
                                .after($("<td/>").html(totals.fines.c$formatAsMoney()))
                                .after($("<td/>").html(totals.penalty.c$formatAsMoney()))
                                .after($("<td/>").html(totals.levy.c$formatAsMoney()))
    }
            function updateCart(event)
            {
                var action  = ($(this).is(":checked") ? "add" : "remove");
                var id = $(this).attr("value").split("|");
                var can     = id[0];
                var year    = id[1];
                var month   = id[2];
                console.log("Can: " + can + "  Year: " + year + "   Month: " + month);

                var record = null;
                for ( var idx=0; idx < paymentsDue.length; idx++ )
                {
                    var dealer = paymentsDue[idx].dealer;
                    var yearsDue = paymentsDue[idx].paymentsDue;
                    if ( dealer.can != can ) continue;
                    record = yearsDue[year][month];
                    break;
                }
                if ( ! record )
                {
                    return;
                }


                var fine = record.mfineLevyBal.c$add(record.mfinePenBal);
                var nsf  = record.mnsfLevyBal.c$add(record.mnsfPenBal);
                var minPayment  = record.amountDue.c$subtract(fine).c$subtract(nsf);
                var totalPayment = record.amountDue;

                // Payment object stores month "as defined" but expands to 2-digits on remove
                month = (month < 10 ? "0" : "") + month;
                $.post( "_paymentsAjax.jsp",
                        { "can": can, "year": year, "month": month, "totals": totalPayment, "minPay": minPayment, "action": action }
                      )
                        .done(
                            function (data, status, jqxhr)
                            {
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