
    var monthNames = [ "", "January", "February", "March", "April", "May", "June",
                            "July", "August", "September", "October", "November", "December"
                        ];

    var isViewOnly = false;
    var emptyCell = $("<td/>").html("&nbsp;");

    var noneCell  = $("<td/>").append($("<i>").addClass("fa fa-times"));
    var someCell  = $("<td/>").append($("<i>").addClass("fa fa-check-square-o"));
    var allCell   = $("<td/>").append($("<i>").addClass("fa fa-check"));

    var viewCell  = $("<td/>").append($("<i>").addClass("fa fa-eye")).append($("<a/>").attr("href","#").html(" view"));
    var newCell   = (isViewOnly ? $("<td/>") : $("<td/>").append($("<i>").addClass("fa fa-eye")).append($("<a/>").attr("href","#").html(" edit")));
    var editCell  = (isViewOnly ? $("<td/>") : $("<td/>").append($("<i>").addClass("fa fa-pencil")).append($("<a/>").attr("href","#").html(" edit")));

    var completeCell  = $("<td/>").addClass("paymentCompleted").html("complete");
    var paymentCell   = $("<td/>").append($("<input/>").attr({"type": "checkbox", "name": "payme"}));

    var $operationWarning = $("#operationWarning");
    var viewOnly          = "<%= viewOnly %>"

    function displayYear(year,data)
    {
        var yearData = data[year];
        if ( ! yearData ) 
        {
            alert("Failed to locate data for specified year: " + year);
            return;
        }

        var category = $("#category").val();
        var currentYear = (new Date()).getFullYear();
        var currentMonth = (new Date()).getMonth()+1;

        var allowEdit = ! isViewOnly && (currentYear-1) <= year;

        var totals = {
                    sales:   0,
                    levy:    0,
                    penalty: 0,
                    fines:   0,
                    nsf:     0,
                    total:   0
                        };

        var records = $("<tbody/>");
        for ( var month=12; month > 0; month-- )
        {
            var defaultDueDOM = (category == "HE"
                                && ( year > 2017 || (year == 2017 && month > 7)) ? "20" : "10");
            if ( currentYear == year && month > currentMonth )
            {
                continue;
            }

            var monthData = yearData[month];
            var dueMonth = month +1;
            var dueYear  = year;

            if ( dueMonth > 12 ){
                dueMonth = 1;
                dueYear = parseInt( year ) + 1;
            }

            var row = $("<tr/>");
            row.append( $("<td/>").html(monthNames[month]) );
            records.append(row);

            if ( ! monthData || (! monthData.salesData && monthData.saved == 0) )
            {
                    monthData.dueDate = dueMonth + "/" + defaultDueDOM + "/"  + dueYear;;
                    row.append(emptyCell.clone().html( monthData.dueDate ))
                        .append(emptyCell.clone())
                        .append(emptyCell.clone())
                        .append(emptyCell.clone())
                        .append(emptyCell.clone())
                        .append(emptyCell.clone())
                        .append(emptyCell.clone())

                        .append(noneCell.clone())
                        .append(noneCell.clone());

                    // Action cell
                    var actionLink = (allowEdit ? newCell.clone() : emptyCell.clone());
                    actionLink.find("a").attr("id",month);
                    row.append(actionLink);

                    // Payment cell
                    row.append(emptyCell.clone());
                    continue;
            }
            else
            {
                monthData.dueDate = dueMonth + "/" + defaultDueDOM + "/"  + dueYear;;
                row.append($("<td/>").html(monthData.dueDate))
                    .append($("<td/>").html(monthData.salesPrice.c$formatAsMoney()))
                    .append($("<td/>").html(monthData.msaleLevyBal.c$formatAsMoney()))
                    .append($("<td/>").html(monthData.msalePenBal.c$formatAsMoney()))
                    .append($("<td/>").html((monthData.mfineLevyBal.c$add(monthData.mfinePenBal).c$formatAsMoney())))
                    .append($("<td/>").html((monthData.mnsfLevyBal.c$add(monthData.mnsfPenBal).c$formatAsMoney())))
                    .append($("<td/>").html(monthData.amountDue.c$formatAsMoney()));

                totals.sales    = totals.sales.c$add(monthData.salesPrice);
                totals.levy     = totals.levy.c$add(monthData.msaleLevyBal);
                totals.penalty  = totals.penalty.c$add(monthData.msalePenBal);
                totals.fines    = totals.fines.c$add(monthData.mfineLevyBal);
                totals.nsf      = totals.nsf.c$add(monthData.mnsfLevyBal);
                totals.total    = totals.total.c$add(monthData.amountDue);

                // Finalized (Submitted)
                if ( monthData.finalized == 0 )
                {
                    row.append(noneCell.clone());
                }
                else if ( monthData.finalized == monthData.reports )
                {
                    row.append(allCell.clone());
                }
                else
                {
                    row.append(someCell.clone());
                }

                // Filed (PYMT Posted)
                if ( monthData.filed == 0 )
                {
                    row.append(noneCell.clone());
                }
                else if ( monthData.filed == monthData.reports )
                {
                    row.append(allCell.clone());
                }
                else
                {
                    row.append(someCell.clone());
                }

                // Action (view/edit)
                if ( monthData.finalized > 0 )
                {
                    var viewLink = viewCell.clone();
                    viewLink.find("a").attr("id",month);
                    row.append(viewLink);
                }
                else if ( allowEdit )
                {                                
                    if ( monthData.salesData )
                    {
                        var editLink = editCell.clone();
                        editLink.find("a").attr("id",month);
                        row.append(editLink);
                    }
                    else
                    {
                        var newLink = newCell.clone();
                        newLink.find("a").attr("id",month);
                        row.append(newLink);
                    }
                }
                else
                {
                    row.append(emptyCell.clone());
                }

                // Payment
                if ( monthData.reports == 0 )
                {
                    row.append(emptyCell.clone());
                }
                else if ( monthData.amountDue == 0 && monthData.reports == monthData.finalized && monthData.reports == monthData.filed )
                {
                    row.append(completeCell.clone());
                }
                else if ( monthData.isPayable && monthData.amountDue > 0 )
                {
                    var cell = paymentCell.clone();
                    cell.find("input[type=checkbox]").attr("value",month);
                    row.append(cell);
                    if ( monthData.isInCart )
                    {
                        cell.find("input[type=checkbox]").prop("checked","checked");
                    }
                }
                else
                {
                    row.append(emptyCell.clone());
                }
            }
        }
        $("#dataTable tbody").remove();
        $("#dataTable").append(records);
        $("#dataTable tbody a").click(gotoSales);
        $("#dataTable tbody input[type=checkbox]").change(updateCart);
        $("#dataTable tfoot tr td").remove();

        // Must be added in reverse order
        $("#dataTable tfoot tr th:first-child")
                                .after($("<td/>").html(totals.total.c$formatAsMoney()))
                                .after($("<td/>").html(totals.nsf.c$formatAsMoney()))
                                .after($("<td/>").html(totals.fines.c$formatAsMoney()))
                                .after($("<td/>").html(totals.penalty.c$formatAsMoney()))
                                .after($("<td/>").html(totals.levy.c$formatAsMoney()))
                                .after($("<td/>").html(totals.sales.c$formatAsMoney()));
    }