<%--
    DN - 02/06/2018 - PRC 194603
        - Report Totals: display all types of sale for the selected report
        - Monthly Totals: display all types of sale in a month
        - For more detail, please look at the attachment

    DN - 05/02/2018 - PRC 1964603
        - Keep asterisk, but remove data in these columns for the imported records
            - Heavy Equipment : ItemName, SerialNumber, Name of Purchaser
            - Motor Vehicle Inventory: Model Year, Make, Vehicle ID, Purchaser Name
            - Housing: Model Year, Make, Serial Number, Purchaser Name
            - Outboard: Model Year, Make, Identification Number, Purchaser Name
        - Add a red asterisk instead of $0.00 and 0 for each of the non HE categories
        - For more details, please look at attachment on 04/25/2018
    DN - 08/07/2018 - PRC 198408
        -Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
--%><%@ include file="_configuration.inc"
%><%
// general
String              chosenReportSeq          = request.getParameter("report_seq");
StringBuffer        sb                       = new StringBuffer();
String              userid                   = request.getParameter("userid");
String              client_id                = request.getParameter("client_id");

String              uptv                     = "";
String []           months                   = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};


boolean            isFinalized               = false;
boolean            hasRecords                = false;
boolean            imported                  = false;

String             dealer_type               = request.getParameter("dealer_type");

// database
Connection         connection                = null;
PreparedStatement  ps                        = null;
ResultSet          rs                        = null;
CallableStatement  cs                        = null;

// from function
double             levbal                    = 0.0;
double             penbal                    = 0.0;
double             fines                     = 0.0;
double             nsf                       = 0.0;
double             totalDue                  = 0.0;

// totals
double             sp                        = 0.0; //sale price
double             td                        = 0.0; //tax due

String             fileDate                  = "";
String             finalizedDate             = "";
String             report_status             = "";
double             timeDiff                  = 0.0;

java.text.DecimalFormat df                   = new java.text.DecimalFormat("$###,###,###,##0.00");

SITUser             sitUser                  = sitAccount.getUser();  


/*  TEST DATA  
userid = "10";
client_id="79000000";
can="H000001";
year="2016";
month="09";
chosenReportSeq="4";
*/
if(can != null){
    try{    
        connection = connect();

        try { // get_amount_due_by_month
            ((oracle.jdbc.OracleConnection)connection).setSessionTimeZone(TimeZone.getDefault().getID());
            cs = connection.prepareCall("{ ?=call vit_utilities.get_amount_due_by_month(?,?,?,?) }");
            //cs = conn.prepareCall("{ ?=call vit_utilities.get_amount_due_by_month(client_id=>?,can=>?,year=>?) }");
            cs.registerOutParameter(1,oracle.jdbc.OracleTypes.CURSOR);
            cs.setString(2, client_id);
            cs.setString(3, can);
            cs.setString(4, year);
            cs.setString(5, month);
            cs.execute();
            rs = (ResultSet) cs.getObject(1);
            while (rs.next()) { 
                levbal   = rs.getDouble("msale_levybal");
                penbal   = rs.getDouble("msale_penbal");
                fines    = rs.getDouble("mfine_levbal") + rs.getDouble("mfine_penbal");
                nsf      = rs.getDouble("mnsf_levbal")  + rs.getDouble("mnsf_penbal");
                totalDue = rs.getDouble("amount_due");
            }
            rs.close();    rs   = null;
        } catch(Exception e){
            SITLog.error(e, "exception: " + e.toString());
        } finally {
            if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
            if ( cs   != null ) { try { cs.close();   } catch (Exception e) {} cs   = null; }
        }

        try { // check to see if this has been finalized

            // 

            ps = connection.prepareStatement("SELECT nvl(TO_CHAR(file_date, 'mm/dd/yyyy'),'No') file_date, "
                                           + "       nvl(report_status, 'none') report_status, "
                                           + "       nvl(TO_CHAR(finalize_date, 'mm/dd/yyyy'),'No') finalize_date, "
                                           + "       nvl(24 * (sysdate - finalize_date), -1) diff_hours "
                                           + "FROM   sit_sales_master "
                                           + "WHERE  client_id=?"
                                           + "          and can=?"
                                           + "          and year=?"
                                           + "          and month=?"
                                           + "          and report_seq=?");                                           
            ps.setString(1, client_id);
            ps.setString(2, can);
            ps.setString(3, year);
            ps.setInt(4, Integer.parseInt(month));
            ps.setInt(5, Integer.parseInt(chosenReportSeq));
            rs = ps.executeQuery();
            if(rs.next()){
                fileDate = rs.getString(1);
                report_status = rs.getString(2);
                timeDiff = rs.getDouble(4);
                finalizedDate = (!"No".equals(rs.getString(3))) ? " ("+rs.getString(3)+")" : "" ;
                //if (finalize_on_pay){
                //    isFinalized = ("C".equals(report_status) || ("I".equals(report_status) && timeDiff <= 1) ? true : false );
                //} else {
                    isFinalized = ("C".equals(report_status)) ? true : false ;
                //}
                //Don't allow additional reports until finalized or filedate exists && payment made in last hour

            }
            //sb.append("<h3>Report# " + chosenReportSeq+"</h3>");
        } catch (Exception e) { 
            SITLog.error(e, "\r\nProblem getting file date, report status, and finalize date in __getStatement.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        } // check to see if this has been finalized

        try { // check to see if this has records
            ps = connection.prepareStatement("select count(*) "
                                          + " from sit_sales  "
                                          + " where client_id = ? and can = ? and year = ? and month = ? and status<>'D' and report_seq = ?");
            ps.setString(1, client_id);
            ps.setString(2, can);
            ps.setString(3, year);
            ps.setInt(4, Integer.parseInt(month));
            ps.setInt(5, Integer.parseInt(chosenReportSeq));
            rs = ps.executeQuery();
            rs.next();
            hasRecords = rs.getInt(1) > 0;
        } catch (Exception e) { 
            SITLog.error(e, "\r\nProblem getting count in __getStatement.jsp\r\n");
            SITLog.info("client_id: " + client_id + ", can: " + can + ", year: " + year + ", month: " + month + ", chosenReportSeq: " + chosenReportSeq);
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        } // check to see if this has been finalized
        
    //PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
    if (finalize_on_pay){
        if("I".equals(report_status) && timeDiff > 1){ // set it back to O
            try { 
                ps = connection.prepareStatement("UPDATE sit_sales_master "
                                               + "  SET report_status = 'O',"
                                               + "      finalize_date = null,"
                                               + "      chngdate = sysdate,"
                                               + "      opercode = decode(opercode,'LOAD', 'LOAD',UPPER(?))"
                                               + "WHERE client_id=?"
                                               + "      and can=?"
                                               + "      and year=?"
                                               + "      and month=?"
                                               + "      and report_seq=?");                                    
               
                ps.setString(1, sitUser.getUserName() );

                ps.setString(2, client_id);
                ps.setString(3, can);
                ps.setString(4, year);
                ps.setString(5, month);
                ps.setInt(6, Integer.parseInt(chosenReportSeq));
                ps.executeUpdate();
                report_status = "O";
                finalizedDate = "";
                SITLog.info("_getStatement: set report_status back to O.\r\nclient_id: " + client_id + ", can: " + can + ", year: " + year + ", month: " + month + ", chosenReportSeq: " + chosenReportSeq);
            } catch (Exception e) { 
                SITLog.error(e, "\r\nProblem setting back to O in __getStatement.jsp\r\n");
                SITLog.info("client_id: " + client_id + ", can: " + can + ", year: " + year + ", month: " + month + ", chosenReportSeq: " + chosenReportSeq);
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            } 
        }

        if("I".equals(report_status) && timeDiff >= 0 && timeDiff <= 1){
            sb.append("<table style='margin: 10px 60px; width: 700px; border: 1px solid black;'>");
            sb.append("    <tr>");
            sb.append("        <td style='text-align: center; background: #C3E4F8; font-weight: bold;' width='33%'>Your payment is in process</td>");
            sb.append("    </tr>");
            sb.append("</table>");
        }
    }
    if(hasRecords){
        try { // write sales table        
            ps = connection.prepareStatement(
                                "select to_char(date_of_sale, 'mm/dd/yyyy'),"
                              + "       model_year,"
                              + "       make,"
                              + "       vin_serial_no,  "
                              + "       purchaser_name,"
                              + "       sale_type,"
                              + "       sales_price,"
                              + "       tax_amount,"
                              + "       sales_seq,"
                              + "       opercode "
                              + " from sit_sales  "
                              + " where client_id = ?"
                              + "       and can = ?"
                              + "       and year = ?"
                              + "       and month = ?"
                              + "       and status<>'D'"
                              + "       and report_seq = ? "
                              + " order by date_of_sale desc");
                              
            ps.setString(1, client_id);
            ps.setString(2, can);
            ps.setString(3, year);
            ps.setInt(4, Integer.parseInt(month));
            ps.setInt(5, Integer.parseInt(chosenReportSeq));
            rs = ps.executeQuery();
            sb.append("<table style='margin: 10px 60px; width: 700px; border: 1px solid black;'>");
            sb.append("    <tr>");
            sb.append("        <td style='text-align: center; background: #C3E4F8; font-weight: bold;' width='33%' no wrap>");
            if(finalize_on_pay){
                sb.append("Finalized? "+ ((isFinalized) 
                    ? "Yes" + finalizedDate 
                    : ("I".equals(report_status) && timeDiff <= 1 && timeDiff >= 0 ) 
                        ? "In Process"
                        : "No") );
            }else{
                sb.append("Finalized? "+ ((isFinalized) ? "Yes" : "No") + finalizedDate);
            }
            
            sb.append("</td>");
            


            sb.append("        <td style='text-align: center; background: #C3E4F8; font-weight: bold;' width='33%'>Filed? "    + fileDate        + "</td>");
            sb.append("        <td style='text-align: center; background: #C3E4F8; font-weight: bold;' width='33%'>Report# "   + chosenReportSeq + "</td>");
            sb.append("    </tr>");
            sb.append("</table>");
            sb.append(" <table id=\"myTable\" style='margin-left: 60px;'>");
            sb.append("     <thead>");
            sb.append("         <tr ><th nowrap id=\"ds\">Date of<br>Sale</th>");
            /***************************************/
            if( !"HE".equals(category) ){
                sb.append("             <th>Model Year</th>"); // !HE
            }
            /***************************************/
            if( "HE".equals(category) ){
                sb.append("             <th>Item Name</th>"); // HE
            } else {
                sb.append("             <th>Make</th>");
            }
            /***************************************/
            if( "HE".equals(category) ){
                sb.append("             <th>Identification/Serial<br>Number</th>");
            } else if( "MH".equals(category) ){
                sb.append("             <th>Unit of Manufacturing<br>Housing Identification/<br>Serial Number</th>");
            }else if( "VTM".equals(category) ){
                sb.append("             <th>Identification Number</th>");
            } else {
                sb.append("             <th>Vehicle ID (VIN)</th>");
            }
            /***************************************/
            if( "HE".equals(category) ){
                sb.append("             <th>Name of Purchaser,<br>Lessee, or Renter</th>");
            } else {
                sb.append("             <th>Purchaser Name</th>");
            }
            /***************************************/
            if( "HE".equals(category) ){
                sb.append("             <th nowrap>Type of<br>Sale,<br>Lease or<br>Rental</th>");
            } else {
                sb.append("             <th nowrap>Type of<br>Sale</th>");
            }
            /***************************************/
            if( "HE".equals(category) ){
                sb.append("             <th>Sale Price,<br>Lease or<br>Rental<br>Amount</th>");
            } else {
                sb.append("             <th>Sale Price</th>");
            }
            /***************************************/
            sb.append("             <th>Unit Property Tax</th>");
            /***************************************/
            sb.append(           (! isFinalized)?"<th style=\"border:none; background: none;\">&nbsp;</th>\r\n":"" );
            sb.append("         </tr>");
            sb.append("     </thead>");
            sb.append("     <tbody>");

            while(rs.next()) {
                sp = Double.parseDouble(rs.getString(7));
                td = Double.parseDouble(rs.getString(8));
                // PRC 194603 show an asterisk in the fields for any month that was imported from the SIT system to the portal
                // For more detail, please look at the attachment in PRC
                if ( !"LOAD".equals (rs.getString(10)) ) {
                    sb.append("<tr><td class=\"dos\">"  + nvl(rs.getString(1), "") + "<input type=\"hidden\" class=\"sales_seq\" value=\"" + rs.getString(9) + "\"></td>\r\n");
                    if( !"HE".equals(category) ){
                       sb.append("    <td class=\"model\">" + nvl(rs.getString(2), "") + "</td>\r\n");
                    }
                    sb.append("    <td class=\"make\">" + nvl(rs.getString(3), "") + "</td>\r\n");
                    sb.append("    <td class=\"vin\">" + nvl(rs.getString(4), "") + "</td>\r\n");
                    sb.append("    <td class=\"purchaser\">" + nvl(rs.getString(5), "") + "</td>\r\n");
                } else {
                    // PRC 194603 - 05/02/2018
                    // Keep asterisk, but remove data in these columns for the imported records
                    // For more details, please look at the attachment
                    imported = true;
                    sb.append("<tr><td id=\"ds\">" + nvl(rs.getString(1), "") + "<span> &#42;</span></td>\r\n");
                    if( !"HE".equals(category) ){
                       sb.append("    <td class=\"model\"><span> &#42;</span></td>\r\n");
                    }
                    sb.append("    <td class=\"make\"><span> &#42;</span></td>\r\n");
                    sb.append("    <td class=\"vin\"><span> &#42;</span></td>\r\n");
                    sb.append("    <td class=\"purchaser\"><span> &#42;</span></td>\r\n");
                }
                sb.append("    <td class=\"type\">" + nvl(rs.getString(6), "") + "</td>\r\n");
                sb.append("    <td class=\"price aRight\">" + formatMoney(sp) + "</td>\r\n");
                sb.append("    <td class=\"tax aRight\">" + formatMoney(td) + "</td>\r\n");
                if (!isFinalized) sb.append("<td nowrap class=\"edit\"><i class=\"fa fa-pencil\"></i> <a href=\"#\" id=\"" + rs.getString(9) + "\">edit</a> / "
                                        + "<i class=\"fa fa-trash\"></i> <a href=\"#\" id=\"" + rs.getString(9) + "\">delete</a></td>\r\n");
                sb.append("</tr>\r\n");
            }//while                                                 y/y   y/n changed           n/y   n/n             
                String val1 = ("HE".equals(category))  ? ((isFinalized)? "7" : "7" )  :  ((isFinalized)? "8" : "9" )  ;
                String val2 = ("HE".equals(category))  ? "4" : "5" ;
                
                // blank row
                sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + val1 + "\">&nbsp;</td></tr>\r\n");
                // PRC 194603(For more details, please look at the attachment)
                // Report Totals: display all types of sale for the selected report
                // Monthly Totals: display all types of sale in a month
                sb.append("<tr><th style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)) + "\">&nbsp;</th>"
                           + "<th style=\"background: #ADD8E6; \">Type of Sale</th>"
                           + "<th style=\"background: #ADD8E6; \">Sales Price</th>"
                           + "<th style=\"background: #ADD8E6; \">Unit Property Tax</th>"
                           + "<th style=\"background: #ADD8E6; \">Number of Units Sold</th></tr>");
                
                for (int i = 0; i<2; i++) {
                    
                    Sale invtSale   = new Sale("","$0.00","","0"); // inventory sale
                    Sale flSale     = new Sale("FL","<span color: red;>&#42;</span>","","<span color: red;>&#42;</span"); // non-inventory sale
                    Sale dlSale     = new Sale("DL","<span color: red;>&#42;</span","","<span color: red;>&#42;</span"); // non-inventory sale
                    Sale rlSale     = new Sale("RL","<span color: red;>&#42;</span","","<span color: red;>&#42;</span"); // non-inventory sale
                    Sale ssSale     = new Sale("SS","<span color: red;>&#42;</span","","<span color: red;>&#42;</span"); // non-inventory sale
                    
                    double spT      = 0.0; //total sale price
                    double tdT      = 0.0; //total tax due
                    
                    int totalUnits  = 0;// total sales units
                        
                    
                    String name     = "Report Totals";
                    
                    if ( i == 1){
                        name = "Monthly Totals";
                        sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + val1 + "\">&nbsp;</td></tr>\r\n");
                    }
                    try {
                        if (i != 1) {
                            
                            ps = connection.prepareStatement(
                                                             "Select count(*) totalSold,"
                                                            +"       sale_type,"
                                                            +"       sum(sales_price) totalSales,"
                                                            +"       sum(tax_amount) totalTax"
                                                            +"  from sit_sales"
                                                            +" where client_id= ?"
                                                            +"  and can = ?"
                                                            +"  and month = ?"
                                                            +"  and year = ?"
                                                            +"  and report_seq = ?"
                                                            +" group by sale_type"
                                                            );
                            ps.setString    (5, chosenReportSeq);
                            
                        } else {
                            
                             ps = connection.prepareStatement(
                                                             "Select count(*) totalSold,"
                                                            +"       sale_type,"
                                                            +"       sum(sales_price) totalSales,"
                                                            +"       sum(tax_amount) totalTax"
                                                            +"  from sit_sales"
                                                            +" where client_id= ?"
                                                            +"  and can = ?"
                                                            +"  and month = ?"
                                                            +"  and year = ?"
                                                            +" group by sale_type"
                                                            );
                        }
                        ps.setString    (1, client_id);
                        ps.setString    (2, can);
                        ps.setInt       (3, nvl(month,0)) ;
                        ps.setString    (4, year);
                        rs = ps.executeQuery();
                        
                   
                         // PRC 194603 - 05/02/2018
                         // Add a red asterisk instead of $0.00 and 0 for each of the non HE categories
                         // For more details, please look at the attachment
                        while ( rs.next() ) {
                            totalUnits     += rs.getInt("totalSold");
                            spT            += nvl(rs.getString("totalSales"),0.0);
                            tdT            += nvl(rs.getString("totalTax"),0.0);
                            String saleType = rs.getString("sale_type");
                            if ( "FL".equals(saleType) ) {
                                flSale.setPrice(displayImported(imported, formatMoney(rs.getString("totalSales"))));
                                flSale.setUnits(displayImported(imported, rs.getString("totalSold")) );
                            } else if ( "DL".equals(saleType) ) {
                                dlSale.setPrice(displayImported(imported, formatMoney(rs.getString("totalSales"))));
                                dlSale.setUnits(displayImported(imported, rs.getString("totalSold")));
                            } else if ( "RL".equals(saleType) ) {
                                rlSale.setPrice(displayImported(imported, formatMoney(rs.getString("totalSales"))));
                                rlSale.setUnits(displayImported(imported, rs.getString("totalSold")));
                            } else if ( "SS".equals(saleType) ){
                                ssSale.setPrice(displayImported(imported, formatMoney( rs.getString("totalSales"))));
                                ssSale.setUnits(displayImported(imported, rs.getString("totalSold")));
                            } else {
                                invtSale.setType(saleType);
                                invtSale.setPrice( formatMoney( rs.getString("totalSales")) );
                                invtSale.setTax(formatMoney(rs.getString("totalTax")));
                                invtSale.setUnits(displayImported(imported, rs.getString("totalSold")));
                            }
                            
                           
                           
                        }
                        
                    } catch (Exception e){
                        
                    } finally {
                        try { rs.close(); } catch (Exception e) { }
                        rs = null;
                        try { ps.close(); } catch (Exception e) { }
                        ps = null;    
                    }// retrieve total sales, total sales tax, total sold units by type of sale
                    sb.append("<tr>"
                                     +"<td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)-1) + "\">&nbsp;</td>"
                                     +"<td style=\"background: #337ab7; color: white; text-align: right;\" nowrap><strong>"+name+"</strong> </td>\r\n"
                                     +"<td style=\"background: #F9F88A;\">"+invtSale.saleType+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+invtSale.salePrice+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+invtSale.saleTax+"</td>"
                                     +"<td style=\"background: #F9F88A;\">"+invtSale.saleUnits+"</td>"
                                     +"</tr>");
                    if ( "MH".equals(invtSale.saleType) ) {
                            sb.append("<tr>"
                                     +"<td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)) + "\">&nbsp;</td>"
                                     +"<td style=\"background: #F9F88A;\">"+rlSale.saleType+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+rlSale.salePrice+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+rlSale.saleTax+"</td>"
                                     +"<td style=\"background: #F9F88A;\">"+rlSale.saleUnits+"</td>"
                                     +"</tr>");
                    } else {
                            sb.append("<tr>"
                                     +"<td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)) + "\">&nbsp;</td>"
                                     +"<td style=\"background: #F9F88A;\">"+flSale.saleType+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+flSale.salePrice+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+flSale.saleTax+"</td>"
                                     +"<td style=\"background: #F9F88A;\">"+flSale.saleUnits+"</td>"
                                     +"</tr>");
                            sb.append("<tr>"
                                     +"<td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)) + "\">&nbsp;</td>"
                                     +"<td style=\"background: #F9F88A;\">"+dlSale.saleType+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+dlSale.salePrice+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+dlSale.saleTax+"</td>"
                                     +"<td style=\"background: #F9F88A;\">"+dlSale.saleUnits+"</td>"
                                     +"</tr>");
                    }
                   
                    sb.append("<tr>"
                                     +"<td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)) + "\">&nbsp;</td>"
                                     +"<td style=\"background: #F9F88A;\">"+ssSale.saleType+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+ssSale.salePrice+"</td>"
                                     +"<td class=\"aRight\" style=\"background: #F9F88A;\" >"+ssSale.saleTax+"</td>"
                                     +"<td style=\"background: #F9F88A;\">"+ssSale.saleUnits+"</td>"
                                     +"</tr>");
                                     
                    sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)) + "\">&nbsp;</td>"
                               + " <th style=\"background: #F9F88A; text-align: center;\">Total</th>\r\n"
                               + " <td class=\"aRight\" style=\"background: #F9F88A;\"><strong>" + df.format(spT) + "</strong></td>\r\n"
                               + " <td class=\"aRight\" style=\"background: #F9F88A;\"><strong>" + df.format(tdT) + "</strong></td>\r\n"
                               + " <td style=\"background: #F9F88A;text-align:center;\"><strong>" + (!imported ? totalUnits:"<span color: red;>&#42;</span>") + "</strong></td>\r\n"
                               + "</tr>\r\n"
                               );
                   
                    sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)+1) + "\">&nbsp;</td>"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\">Levy Due:</td>\r\n"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\"><Strong>"+formatMoney(levbal)+"</Strong></td>\r\n"
                               + "</tr>\r\n"
                               );
                    
                    sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)+1) + "\">&nbsp;</td>"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\">Penalty Due:</td>\r\n"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\"><Strong>"+formatMoney(penbal)+"</Strong></td>\r\n"
                               + "</tr>\r\n"
                               );
                   
                    sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)+1) + "\">&nbsp;</td>"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\">Fines:</td>\r\n"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\"><Strong>"+formatMoney(fines)+"</Strong></td>\r\n"
                               + "</tr>\r\n"
                               );
                  
                    sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)+1) + "\">&nbsp;</td>"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\">NSF Due:</td>\r\n"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\"><Strong>"+formatMoney(nsf)+"</Strong></td>\r\n"
                               + "</tr>\r\n"
                               );
                 
                     sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + (Integer.parseInt(val2)+1) + "\">&nbsp;</td>"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\">Total:</td>\r\n"
                               + "<td class=\"aRight\" style=\"background: #F9F88A;\"><Strong>"+formatMoney(totalDue)+"</Strong></td>\r\n"
                               + "</tr>\r\n"
                               );
                }
             
                
                // blank row
                sb.append("<tr><td style=\"background: none; border: none;\" colspan=\"" + val1 + "\">&nbsp;</td></tr>\r\n");

                
                sb.append("</tbody></table>");
            } catch (Exception e) { 
                SITLog.error(e, "\r\nProblem looping in __getStatement.jsp\r\n");
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }// try get dealerships


} else { // has no records
    sb.append("<div id='norecords' class='norecords' style='width: 600px; text-align: center; padding-top: 15px; font-size: 20px; margin-left: 100px;'>no records found</div>");
    sb.append("<div id='norecords' class='norecords' style='width: 600px; text-align: center; padding-top: 15px; font-size: 20px; margin-left: 100px;font-size:14px;'>If you wish to continue with no sales for this month,<br>click the \"Confirm Totals\" button</div>");
} 

/* TESTING
sb.append("<div id='status'>"
        + "Has Records: "   + hasRecords    + ", "
        + "isFinalized: "   + isFinalized   + ", "
        + "timeDiff: "     + timeDiff     + ", "
        + "finalizedDate: " + finalizedDate
        + "</div>");
 */        
sb.append("<div id='status'>");
sb.append("    <input type='hidden' id='hasRecords'    value='"+hasRecords+"'>");
sb.append("    <input type='hidden' id='isFinalized'   value='"+isFinalized+"'>");
sb.append("    <input type='hidden' id='timeDiff'     value='"+timeDiff+"'>");
sb.append("    <input type='hidden' id='finalizedDate' value='"+finalizedDate+"'>");
sb.append("    <input type='hidden' id='report_status' value='"+report_status+"'>");
sb.append("</div>");
            try {
            // note that Dawn and Fakhar said (1/5/2016) to use this function, which returns .002 for H00001 | 2013 | 79000000. 
            // What I was originally pulling was ~.197666 from the get_uptv function.
            // Not showing up for 2016 yet
                ps = connection.prepareStatement("SELECT act_subsystems.taxunit_monthly_rate(?,?,?) FROM DUAL");
                ps.setString(1, can);
                ps.setLong(2, Long.parseLong(year));
                ps.setLong(3, Long.parseLong(client_id));
                rs = ps.executeQuery();
                if(rs.next()) uptv = rs.getString(1); else uptv = "0";
                sb.append("<input type=\"hidden\" id=\"uptv\" value=\"" + uptv + "\" >");
            } catch (Exception e) { 
                SITLog.error(e, "\r\nProblem getting tax rate in __getStatement.jsp\r\n");
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }// try get dealerships 





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
    } // if can != null
%><%= sb.toString() %><%!

public class Sale {
    public Sale(){}
    
    public Sale( String type, String price,
                String tax, String units ){
        this.setType(type)
            .setPrice(price)
            .setTax(tax)
            .setUnits(units);
    }
    
    public Sale setType (String type){
        saleType = type;
        return this;
    }
    
    public Sale setPrice(String price){
        salePrice = price;
        return this;
    }
    
    public Sale setTax(String tax){
        saleTax = tax;
        return this;
    }
    
    public Sale setUnits(String units) {
        saleUnits = units;
        return this;
    }
    
    public String saleType      = null;
    public String salePrice     = null;
    public String saleTax       = null;
    public String saleUnits     = "0";
}

// PRC 194603 - 05/02/2018
// Dislay function will determine when data or asterisk is displayed
public String displayImported(boolean imported, String data ){
    return (!imported ? data : "<span color: red;>&#42</span>");
}
%>