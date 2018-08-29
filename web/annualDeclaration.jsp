<%--
    DN - 02/12/2018 - PRC 195488
        only apply to Dallas County
        let the user update 2 column "Break of Sales (number of units sold) last year" and "Breakdown of Sales Amounts last year" of the account having the imported months
        2 columns should no longer populate from the system
        For more detail, please look at the attachment in PRC
         
    DN - 02/13/2018 - PRC 194602
        only apply to Harri County
        let the user finalize the annual statement if all available months in the startDate's year are finalized
        
    DN - 5/18/2018 - PRC 194602
        Updated the code logic, so the user can close the annual statement based on the scenarios stated in the attached email
        Apply to Dallas and Harris County
        Look at the recent attached email for more information
        
    DN - 06/19/2018 - PRC 195488
        Updated code, the changes will apply to all clients

     DN - 08/06/2018 - PRC 198588
        Updated code, in case of the imported records, the user must fill in all of fields before closing Year
        Updated code, in case of the imported records, the value of client pref "SIT_PORT_INCL_LOAD_ANN_DEC" is "Y", the data of fields will be retrieved from database, but all fields are editable.
        
--%><%@ include file="_configuration.inc"%>
<% 
    // general
    String              pageTitle                   = "Annual Declaration";
    String              client_id                   = (String) session.getAttribute( "client_id");
    String              userid                      = (String) session.getAttribute( "userid");
    boolean             showWaccount                = true;
    boolean             showWyearSelect             = false;
    boolean             showWyearDisplay            = true;
    boolean             showWyearMonthDisplay       = false;
    boolean             showUpload                  = false;
    boolean             importedMonths              = false;
    java.text.DecimalFormat df                      = new java.text.DecimalFormat("$###,###,###.00");
    StringBuffer sb = new StringBuffer();
month = "13";
    // totals
    int                 finalized                   = 0;
    String              countDL                     = "";
    String              countFL                     = "";
    String              countMain                   = "";
    String              countSS                     = "";
    String              countRL                     = "";
    String              amountDL                    = "";
    String              amountFL                    = "";
    String              amountMain                  = "";
    String              amountSS                    = "";
    String              amountRL                    = "";
    String              report_sequence             = nvl(request.getParameter("report_seq"), "1");
    String              pdf_url                     = "";
    
    String              invCount                    = "";
    String              invAmount                   = "";

    String              rsCount                     = "";
    String              rsAmount                    = "";

    String              fsCount                     = "";
    String              fsAmount                    = "";

    String              dsCount                     = "";
    String              dsAmount                    = "";

    String              ssCount                     = "";
    String              ssAmount                    = "";
    
    // PRC 194602 let the user finalize the annual statement if all available months in the startDate's year are finialized
    String              startDate                   = "";
    int                 startMonth                  = 0;
    String              startYear                   = "";
    int                 requiredMonthsView          = 13;
    int                 requiredMonthsClose         = 12;
    
    // PRC 198588 in case of the imported records, if the value of sit codeset "SIT_PORT_INCL_LOAD_ANN_DEC" is "Y",
    //the data of fields will be retrieved from database, but all fields are editable.
    boolean             includedLoad                = false;
    
    // database
    Connection          connection                  = null;
    PreparedStatement   ps                          = null;
    ResultSet           rs                          = null;

    // form names
    String              form_annual                 = "";
    if ("50-246".equals(form_name)) form_annual     = "50_244"; else
    if ("50-260".equals(form_name)) form_annual     = "50_259"; else
    if ("50-266".equals(form_name)) form_annual     = "50_265"; else
    if ("50-268".equals(form_name)) form_annual     = "50_267"; 

if(request.getParameter("can") != null){
    connection = connect();
    try{ // big outer
        includedLoad = "Y".equals( nvl( getSitClientPref(connection, ps, rs, client_id, "SIT_PORT_INCL_LOAD_ANN_DEC") ) );

        try { // Step #1 get the dealer info          
            ps = connection.prepareStatement("select count(can), to_char(sum(sales_price), '$999,999,999.00') amount, sale_type"
                                          + " from   sit_sales "
                                          + " where  can = ? and year=? and status <> 'D' "
                                          + " group by sale_type"
                                          + " order by sale_type");
            ps.setString(1, can);
            ps.setInt(2, Integer.parseInt(year));
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
            }
        } catch (Exception e) {
            SITLog.error(e, "\r\nProblem getting totals in annualDeclaration.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try get dealerships
        
        // PRC 194602 let the user finalize the annual statement if all available months in the startDate's year are finialized 
        // Updated getStartDate function
        startDate = getStartDate( connection, ps, rs, client_id, can, year );
        if ( isDefined( startDate ) ) {
            startYear = getYear( convertToDate( startDate ) );
        }
        
        if ( startYear.equals( year ) ) {
            startMonth = getMonth( convertToDate( startDate ) );
            requiredMonthsView   = 13 - startMonth + 1;
            requiredMonthsClose  = 12 - startMonth + 1;
        }

        //PRC 194602 - 05.18.2018
        //Updated the query, it will count the minimum finalized statements needed to close the annual statement
        //PRC 194602 - 06/14/2018
        //if startYear does not equal the filing year, we will count all finalized monthly statements regardless of opercode
        //if startYear equals the filing year, we only count the  finalized monthly statements with opercode which does not equal"LOAD"
        try { // check to see if this has been finalized
        
            if ( startYear.equals( year ) ) {
                ps = connection.prepareStatement("select count(*) from sit_sales_master "
                                               + "where client_id=?"
                                               + " and can=?"
                                               + " and year=?"
                                               + " and report_status='C'"
                                               + " and report_seq=1"
                                               + " and month >= ?");
                ps.setInt(4, startMonth);
            } else {
                 ps = connection.prepareStatement("select count(*) from sit_sales_master "
                                               + "where client_id=?"
                                               + " and can=?"
                                               + " and year=?"
                                               + " and report_status='C'"
                                               + " and report_seq=1");
            }
            ps.setString(1, client_id);
            ps.setString(2, can);
            ps.setString(3, year);
            
            rs = ps.executeQuery();
            rs.next();
            finalized = rs.getInt(1);
        
        } catch (Exception e) { 
            SITLog.error(e, "\r\nProblem getting count in annualDeclaration.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        } // check to see if this has been finalized

        try {// PRC 195488 check if there are imported months in this account and only apply to Dallas County
            ps = connection.prepareStatement(" select count(*) as importedMonths"
                                            +"  from sit_sales_master"
                                            +" where client_id = ?"
                                            +"      and can = ?"
                                            +"      and year = ?"
                                            +"      and opercode= 'LOAD'"
                                            );
            ps.setString(1, client_id);
            ps.setString(2, can);
            ps.setString(3, year);
            
            rs = ps.executeQuery();
            
            if ( rs.next() ) {
                importedMonths = rs.getInt("importedMonths") > 0;
            }
        
        } catch (Exception e){
            SITLog.error(e, "\r\nProblem checking if there are the imported months in the account in annualDeclaration.jsp \r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }
       
        if( finalized == requiredMonthsView
            && importedMonths ) {
            try {// PRC 195488 retrieve the breakdown sales and the breakdown sales amounts from sit_sales_master
                ps = connection.prepareStatement(" select"
                                                +"      inventory_sales_units,"
                                                +"      fleet_sales_units,"
                                                +"      dealer_sales_units,"
                                                +"      subsequent_sales_units,"
                                                +"      retail_sales_units,"
                                                +"      inventory_sales_amount,"
                                                +"      fleet_sales_amount,"
                                                +"      dealer_sales_amount,"
                                                +"      subsequent_sales_amount,"
                                                +"      retail_sales_amount"
                                                +"  from sit_sales_master"
                                                +" where client_id = ?"
                                                +"      and can = ?"
                                                +"      and year = ?"
                                                +"      and month = ?"
                                                +"      and report_status= 'C'"
                                                );
                ps.setString(1, client_id);
                ps.setString(2, can);
                ps.setString(3, year);
                ps.setInt   (4, 13);
                
                rs = ps.executeQuery();
                
                if ( rs.next() ) {
                    invCount    = nvl( rs.getString("inventory_sales_units"),"0" );
                    fsCount     = nvl( rs.getString("fleet_sales_units"),"0");
                    dsCount     = nvl( rs.getString("dealer_sales_units"),"0");
                    ssCount     = nvl( rs.getString("subsequent_sales_units"),"0");
                    rsCount     = nvl( rs.getString("retail_sales_units"),"0");
                    
                    invAmount   = nvl( rs.getString("inventory_sales_amount"),"0.00");
                    fsAmount    = nvl( rs.getString("fleet_sales_amount"),"0.00");
                    dsAmount    = nvl( rs.getString("dealer_sales_amount"),"0.00");
                    ssAmount    = nvl( rs.getString("subsequent_sales_amount"),"0.00");
                    rsAmount    = nvl( rs.getString("retail_sales_amount"),"0.00");
                    
                }
            
            } catch (Exception e){
                SITLog.error(e, "\r\nProblem checking if there are the imported months in the account in annualDeclaration.jsp \r\n");
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }// retrieve the breakdown sales and the breakdown sales amount from "sit_sales_master" table after the annual form is finalized
        }
        
        
        

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
            // I tried a ternary statement (i = (can.equals(d.can)) ds.size() ? : i++;) but it didn't work well
        }
    }
    
    
} // if(request.getParameter("can") != null)

if (finalized == requiredMonthsView){
    try{
    %>

        <%@ include file="_viewForm.inc"%>

    <% 
    }catch(Exception e){
        out.print("Exception: " + e.toString());
    } 
}//if
 %>
<%@ include file="_top1.inc" %>
<!-- include styles here -->
<style>
    .ui-datepicker-next,.ui-datepicker-prev{display:none;}
    #createSaleForm label { font-size: 11px;}
    #myTable tr th {text-align: right; padding-right: 10px; }
    #myTable tr td {text-align: right; padding-right: 10px; }
    #myTable tr td input {padding-left: 10px; text-align: right; }
    #requiredStar           { display: inline-block; padding-top: 10px; padding-left: 17px; }
    #fieldNotice            { display: none; padding-top: 10px; color: red; float: right; }
    .invalidField           { border-color: red; }
</style>
        <%@ include file="_top2.inc" %>
        <%= recents %>
        <%@ include file="_widgets.inc" %>
    </div><!-- #bodyTop -->

    <div id="body" >
        <div id="myTableDiv">
            <div id="testDiv" name="testDiv"></div>
            <div id="formDiv" style="padding-bottom: 10px;">
                <button style="margin-left: 130px;" id="btnPrev" name="btnPrev" class="btn btn-primary"><i class="fa fa-arrow-left"></i> Yearly Summary</button>
                <form style="display: inline;" action="<%= pdf_url %>" target="_blank">
                    <button style="margin-left: 30px;" id="btnViewForm" name="" 
                    <%= (finalized == requiredMonthsView || (!"#".equals(pdf_url) && isDefined(pdf_url))) 
                        ? "class=\"btn btn-primary\"" 
                        : "class=\"btn btn-disabled\" disabled" 
                    %>>View Form</button>
                </form>
                <button style="margin-left: 30px;" id="btnFinalize" name="btnFinalize" 
                <%= (finalized == requiredMonthsClose) ? "class=\"btn btn-primary\"" : "class=\"btn btn-disabled\" disabled" %>>Close Year</button>
                <div style="width:550px;">
                    <div id="requiredStar"><span style="color: red;">*</span><b>Required</b></div>
                    <div id="fieldNotice"><b>You must fill in all of the fields below</b></div>
                </div>
            </div><%  %>
            <!--PRC 195488 the inputs from 2 columns will be used to populate the annual declaration form for all dealer types -->
    <form id="navigation" action="yearlySummary.jsp" method="post">
            <table id="myTable">
                <thead>
                    <tr>
                        <th nowrap>Breakdown of Sales (number of units sold) last year</th>
                        <th nowrap>Breakdown of Sales Amounts last year</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td nowrap>Net <%= categoryNomen %> Inventory 
                                   <input type="text" disabled="true"
                                            class="inventory"
                                            id="invCount" name="invCount" 
                                            style="width:43px; padding-right: 5px;" 
                                            value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? invCount 
                                                                                                             : ( includedLoad ?  nvl(countMain, "0") 
                                                                                                                              : "" )) 
                                                                      :  nvl(countMain, "0") %>"
                                            onkeyup="javascript:isNumber('invCount');"
                                            onchange="javascript:isNumber('invCount');"
                                            /></td>
                        <td nowrap>Net <%= categoryNomen %> Inventory 
                                   <input type="text" disabled="true"
                                            class="inventory"
                                            id="invAmount" name="invAmount" 
                                            style="width:130px; padding-right: 5px;" 
                                            value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? invAmount
                                                                                                             :( includedLoad ?  nvl(amountMain, "$0.00") 
                                                                                                                             : "" )) 
                                                                      :  nvl(amountMain, "$0.00") %>"
                                            onkeyup="javascript:isNumber('invAmount');"
                                            onchange="javascript:isNumber('invAmount');"
                                            /></td>
                    </tr>
                    <% if ("MH".equals(category)) { %><!-- MH is the one with RL and no FL or DL -->
                        <tr>
                            <td>Retail Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="rsCount" name="rsCount" 
                                                    style="width:43px;  padding-right: 5px;" 
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? rsCount 
                                                                                                                     : ( includedLoad ?  nvl(countRL, "0") 
                                                                                                                                      : "" )) 
                                                                              : nvl(countRL, "0") %>"
                                                    onkeyup="javascript:isNumber('rsCount');"
                                                    onchange="javascript:isNumber('rsCount');"
                                                    /></td>
                            <td>Retail Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="rsAmount" name="rsAmount" 
                                                    style="width:130px; padding-right: 5px;"
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? rsAmount 
                                                                                                                     : ( includedLoad ?  nvl(amountRL, "$0.00") 
                                                                                                                                      : "")) 
                                                                              : nvl(amountRL, "$0.00") %>"
                                                    onkeyup="javascript:isNumber('rsAmount');"
                                                    onchange="javascript:isNumber('rsAmount');"   
                                                    /></td>
                        </tr>  
                    <% } else { %>
                        <tr>
                            <td>Fleet Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="fsCount" name="fsCount" 
                                                    style="width:43px;  padding-right: 5px;" 
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? fsCount 
                                                                                                                     : ( includedLoad ?  nvl(countFL, "0") 
                                                                                                                                      : "" )) 
                                                                              : nvl(countFL, "0") %>"
                                                    onkeyup="javascript:isNumber('fsCount');"
                                                    onchange="javascript:isNumber('fsCount');"
                                                    /></td>
                            <td>Fleet Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="fsAmount" name="fsAmount" 
                                                    style="width:130px; padding-right: 5px;" 
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? fsAmount 
                                                                                                                     : ( includedLoad ?  nvl(amountFL, "$0.00") 
                                                                                                                                      : "" )) 
                                                                              : nvl(amountFL, "$0.00") %>"
                                                    onkeyup="javascript:isNumber('fsAmount');"
                                                    onchange="javascript:isNumber('fsAmount');"
                                                    /></td>
                        </tr> 
                        <tr>
                            <td>Dealer Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="dsCount" name="dsCount" 
                                                    style="width:43px;  padding-right: 5px;" 
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? dsCount 
                                                                                                                     : ( includedLoad ?  nvl(countDL, "0") 
                                                                                                                                      : "" )) 
                                                                              : nvl(countDL, "0") %>"
                                                    onkeyup="javascript:isNumber('dsCount');"
                                                    onchange="javascript:isNumber('dsCount');"                                              
                                                    /></td>
                            <td>Dealer Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="dsAmount" name="dsAmount" 
                                                    style="width:130px; padding-right: 5px;" 
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? dsAmount 
                                                                                                                     : ( includedLoad ?  nvl(amountDL, "$0.00") 
                                                                                                                                      : "" )) 
                                                                              : nvl(amountDL, "$0.00") %>"
                                                    onkeyup=javascript:isNumber('dsAmount');
                                                    onchange="javascript:isNumber('dsAmount');"                                                 
                                                    /></td>
                        </tr>
                    <% } %>
                    <tr>
                        <td>Subsequent Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="ssCount" name="ssCount" 
                                                    style="width:43px;  padding-right: 5px;" 
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? ssCount 
                                                                                                                     : ( includedLoad ?  nvl(countSS, "0") 
                                                                                                                                     : "" )) 
                                                                              : nvl(countSS, "0") %>"
                                                    onkeyup="javascript:isNumber('ssCount');"
                                                    onchange="javascript:isNumber('ssCount');"
                                                    /></td>
                        <td>Subsequent Sales <input type="text" disabled="true"
                                                    class="inventory"
                                                    id="ssAmount" name="ssAmount" 
                                                    style="width:130px; padding-right: 5px;" 
                                                    value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? ssAmount 
                                                                                                                     : ( includedLoad ?  nvl(amountSS, "$0.00") 
                                                                                                                                      : "" )) 
                                                                              : nvl(amountSS, "$0.00") %>"
                                                    onkeyup="javascript:isNumber('ssAmount');"
                                                    onchange="javascript:isNumber('ssAmount');"                                        
                                                    /></td>
                    </tr>

                    <tr>
                        <td style="background: #F9F88A;text-align:left;padding: 5px;font-size: 10px;" colspan="2">
                            <% if ( "MV".equals(category) ) { %> 
                            State the market value of the motor vehicle inventory for the current tax year, as computed under Tax Code Section 23.121. Market value is total annual sales less sales to dealers, fleet transactions, and subsequent sales, from the dealer's motor vehicle inventory for the previous 12-month period corresponding to the prior tax year divided by 12. Total annual sales is the total of the sales price from every sale from a dealer's motor vehicle inventory for a 12-month period. If you were not in business for the entire 12-month period, report the total number of sales for the months you were in business. The chief appraiser will determine the inventory's market value.
                            <% } else if ( "HE".equals(category) ) { %> 
                            State the market value of your net heavy equipment inventory for the current tax year, as computed under Tax Code Section 23.1241. Market value on January 1 is total annual sales (less fleet transactions, dealer sales, and subsequent sales) for the previous 12-month period corresponding to the prior tax year divided by 12. If you were not in business for the entire 12-month period, report the number of months you were in business and the total number of sales for those months; the chief appraiser will estimate your inventory's market value.<br><br>Total annual sales includes the sales price for each sale of heavy equipment inventory in a 12-month period PLUS lease and rental payment(s) received for each lease or rental in that 12-month period. This will be the same amount as the net heavy equipment inventory transaction amount (see Section 5, the first box in Part II) and divide by 12 to yield your market value for this tax year. If you were not in business for the entire preceding year, the chief appraiser will estimate your inventory's market value.
                            <% } else if ( "MH".equals(category) ) { %> 
                            State the market value of your retail manufactured housing inventory for the current tax year, as computed under Sec. 23.127, Tax Code (total annual sales from the retailer's manufactured housing inventory for the previous 12-month period corresponding to the prior tax year divided by 12 equals market value). If you were not in business for the entire 12-month period, report the number of months you were in business and the total number of sales for those months. The chief appraiser will determine your inventory's market value.
                            <% } else if ( "VM".equals(category) ) { %> 
                            State the market value of the inventory for the current tax year as computed under Tax Code Section 23.124. Market value is total annual sales from the dealer's inventory less sales to dealers, fleet transactions, and subsequent sales for the previous 12-month period corresponding to the prior tax year divided by 12. Total annual sales is the total of the sales price from every sale from the inventory for a 12-month period. If you were not in business for the entire 12-month period, report the sales for those months you were in business and the chief appraiser will determine the inventory's market value.
                            <% } %> 
                        </td>
                    </tr>   
                    <tr>
                        <td style="background: #edf3fe;; text-align: center;" colspan="2">
                            <div style="float:left;margin-left:10px; font-weight: bold;font-size: 11px;text-align: center;">
                                Dealer's Net Motor Vehicle Inventory Sales for Prior Year<br>
                                <input type="text" id="priorTotal" name = "priorTotal" value="<%= importedMonths ? (( finalized == requiredMonthsView ) ? invAmount 
                                                                                                                                                        : ( includedLoad ?  nvl(amountMain, "$0.00") 
                                                                                                                                                                         : "" ))  
                                                                                                                 : nvl(amountMain, "$0.00") %>" readonly="readonly">
                            </div>
                            <div style="float:left;margin-left:20px;padding-top:18px;">
                                / 12 =
                            </div>
                            <div style="float:right;margin-left:10px; font-weight: bold;font-size: 11px;">Market Value for Current Tax Year<br>
                                <input type="text" id="market" name = "market" value="????" readonly="readonly">
                            </div>
                        </td>
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

    
        <input type="hidden" name="client_id" id="client_id" value="<%= client_id %>">
        <input type="hidden" name="can" id="can" value="<%= can %>">
        <input type="hidden" name="name" id="name" value="">
        <input type="hidden" name="year" id="year" value="">
        <input type="hidden" name="month" id="month" value="">
        <input type="hidden" name="form_name" id="form_name" value="">
        <input type="hidden" name="category" id="category" value="<%= category %>">
        <input type="hidden" name="current" id="current" value="<%= current_page %>">
        <input type="hidden" name="bizStart" id="bizStart" value="<%= d.years[0] %>">
        <input type="hidden" name="importedMonths" id="importedMonths" value="<%= importedMonths %>">
    </form>
   
<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script>
        $(document).ready(function() {
            if( "<%= importedMonths %>" == "true"
                && "<%= finalized == requiredMonthsView %>" == "false" ){
                $("#myTable input").prop("disabled", false);
                
            } else if ("<%= finalized == requiredMonthsView %>" == "true") {
                $("#myTable input").prop("disabled", true);
            }
            var newValue = $("#priorTotal").val().replace(/[$,]/g,"")/12;
            newValue = "$" + newValue.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');
            $("#market").prop("value", newValue);

            //$("#btnViewForm").click(function(e){
            //    e.preventDefault();
            //    e.stopPropagation();
            //    var $theForm = $("form#navigation");
            //    var can = "<%= can %>";
            //    var year = "<%= year %>";
            //    var month = 13;
            //    var form_name = "<%= form_name %>";
            //    var form_annual = "<%= form_annual %>";
            //    $theForm.children("#can").prop("value", can);
            //    $theForm.children("#year").prop("value", year);
            //    $theForm.children("#month").prop("value", month);
            //    $theForm.children("#form_name").prop("value", form_name);
            //    $theForm.prop("method", "post"); 
            //    $theForm.prop("action", "forms/viewForm.jsp"); 
            //    $theForm.prop("target", "_blank");
            //    $theForm.submit();
            //});

            $("#btnFinalize").click(function(e){
                e.preventDefault();
                e.stopPropagation();
                var $theForm = $("form#navigation");
                var can = "<%= can %>";
                var year = "<%= year %>";
                var month = "<%= month %>";
                var form_name = "<%= form_name %>";
                var form_annual = "<%= form_annual %>";
                $("#can").prop("value", can);
                $("#year").prop("value", year);
                $("#month").prop("value", month);
                $("#form_name").prop("value", form_name);
                $theForm.prop("action", "forms/" + form_annual + ".jsp"); 
                $theForm.prop("target", "");
                // PRC 198588 -  in case of the imported records, the user must fill in all of fields before closing Year
                if ( areFieldsValid() ) {
                     $theForm.submit();
                } 
            });

            $("#btnPrev").click(function(e){
                e.preventDefault();
                e.stopPropagation();
                var can = "<%= can %>";
                var year = "<%= year %>";
                var $theForm = $("form#navigation");
                $theForm.children("#can").prop("value", can);
                $theForm.children("#year").prop("value", year);
                $theForm.prop("target", "");
                $theForm.prop("action", "yearlySummary.jsp");
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

        });//doc ready
        
        function isNumber(id){
            var numericPattern = /^\d+(\.\d{1,2})?$/;
            if ( ! numericPattern.test( $("#"+id).val() )) {
                $("#"+id).val("");
            } 
            
            if (id == "invAmount") {
                $("#priorTotal").val( $("#invAmount").val() ) ;
                var marketValue = $("#priorTotal").val().replace(/[$,]/g,"")/12;
                marketValue = "$" + marketValue.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');
                $("#market").prop("value", marketValue);
            }
        }
        
        // PRC 198588 -  in case of the imported records, the user must fill in all of fields before closing Year
       function areFieldsValid(){
           var fieldsValid = true;
           
           if ("true"=="<%= importedMonths %>") {
               for (i = 0; i < $(".inventory").length; i++){
                   if ( $('.inventory:eq('+ i +')').val() == "" ){
                       $('.inventory:eq('+ i +')').addClass("invalidField");
                       $("#myTableDiv #fieldNotice").css("display","inline-block");
                       fieldsValid = false;
                   } else {
                        $('.inventory:eq('+ i +')').removeClass("invalidField");
                   } 
               }
           }
           
           return fieldsValid;
       }
    </script>
</body>
</html>