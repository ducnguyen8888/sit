<%--
    DN - 08/07/2018 - PRC 198408
        - Updated code, login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
    DN - 09/12/2018 - PRC 197579
        - Updated code, all of insert, delete and update requests won't be executed if the users have the "view only" right
--%><%@ include file="_configuration.inc"%>
<%
 can =  "";
String date_of_sale =  "";
String model_year =  "";
String make =  "";
String vin_serial_no =  "";
String sale_type =  ""; //MV, RL, etc.
String purchaser_name =  "";
String sales_price =  "";
String tax_amount =  "";
String client_id =  "";
 year =  ""; //of record
 month =  ""; //of record
String sales_seq =  ""; // I need to create this for CREATE
String report_sequence =  ""; // I need to create this for CREATE
boolean report_seq_exists = false;
String status =  ""; //IT, D, C
 form_name =  ""; // based on category
String uptv_factor =  "";
String pending_payment =  "";
String input_date =  "";//when record was inserted
String action = "";
String dealer_type = "";

SITUser    sitUser    = sitAccount.getUser();


// ******** NOTES ********
//if (record has been filed) don't update
//if (insert) get max(sales_seq) where year = ? and month = ?
//

StringBuffer sb = new StringBuffer();
sb.append("\r\n");

can             = nvl(request.getParameter("can"));
date_of_sale    = nvl(request.getParameter("date_of_sale"));
model_year      = nvl(request.getParameter("model_year"));
make            = nvl(request.getParameter("make"));
vin_serial_no   = nvl(request.getParameter("vin_serial_no"));
sale_type       = nvl(request.getParameter("sale_type"));
purchaser_name  = nvl(request.getParameter("purchaser_name"));
sales_price     = nvl(request.getParameter("sales_price"));
tax_amount      = nvl(request.getParameter("tax_amount"));
client_id       = nvl(request.getParameter("client_id"));
year            = nvl(request.getParameter("year"));
month           = nvl(request.getParameter("month"));
report_sequence = nvl(request.getParameter("report_seq"));
sales_seq       = nvl(request.getParameter("sales_seq"));
status          = nvl(request.getParameter("status"));
form_name       = nvl(request.getParameter("form_name"));
uptv_factor     = nvl(request.getParameter("uptv_factor"));
pending_payment = nvl(request.getParameter("pending_payment"));
input_date      = nvl(request.getParameter("input_date"));
action          = nvl(request.getParameter("action"));
dealer_type     = nvl(request.getParameter("dealer_type"));
/* PRESET VALUES 
can = "H000001";
date_of_sale = "11/01/2013";
model_year = "2013";
make = "test";
report_sequence = "2";
vin_serial_no = "testtggtt";
sale_type = "MV";
purchaser_name = "test";
sales_price = "1233.33";
tax_amount = "242.55";
client_id = "79000000";
year = "2016";
month = "09";
form_name = "50-246";
sales_seq = "98";
uptv_factor = ".19666667";
pending_payment = "N";
input_date = "09/09/1999";
status = "C";
action = "new"; // new or edit
dealer_type = "3";
*/
month = month.length() == 1 ? "0" + month : month; // makes 7 = 07
// PRC 197579 - Updated code, all of insert, delete and update requests won't be executed if the users have the "view only" right
if( isDefined(can)
        && !viewOnly ){
    Connection connection = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try{    
        connection = connect();
        if(request.getParameter("removeMe") != null && "yes".equals(request.getParameter("removeMe"))){
            payments.remove(can, year, month);
        }        
        // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
        // ************** ResetMe **************
        if (isDefined(action) && "resetMe".equals(action)){
            try {
                ps = connection.prepareStatement(
                                    "update sit_sales_master"
                                  + " set report_status='O',"
                                  + "       finalize_date=null,"
                                  + "       chngdate = sysdate,"
                                  + "       opercode = decode(opercode,'LOAD','LOAD',UPPER(?)"
                                  + " where client_id = ?"
                                  + " and can = ?"
                                  + " and year = ?"
                                  + " and month = ?"
                                  + " and report_seq = ? ");
                
                ps.setString(1, sitUser.getUserName());
                ps.setString(2, client_id);
                ps.setString(3, can);
                ps.setString(4, year);
                ps.setString(5, month);
                ps.setString(6, report_sequence);

                if (ps.executeUpdate() > 0){
                    sb.append("update success\r\n");
                } else {
                    sb.append("update failure\r\n");
                }
   
            } catch (Exception e) { SITLog.error(e, "Trying to reset in _writeInfo.jsp: client_id: " + client_id + ", can: " + can + ", year: " + year + ", month: " + month + ", report_sequence: " + report_sequence);
            } finally {
                try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
                rs = null;
                try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
                ps = null;
            }// try reset          
        } // if (delete)
        // ************** /ResetMe **************
        // ************** DELETE **************
        if (isDefined(action) && "delete".equals(action)){
            try {
                ps = connection.prepareStatement("DELETE FROM sit_sales WHERE year = ? and month = ? and client_id = ? and can = ? and sales_seq = ?");
                ps.setString(1, year);
                ps.setString(2, month);
                ps.setString(3, client_id);
                ps.setString(4, can);
                ps.setString(5, sales_seq);

                if (ps.executeUpdate() > 0){
                    sb.append("update success\r\n");
                } else {
                    sb.append("update failure\r\n");
                }
   
            } catch (Exception e) { sb.append("<br>Exception in executeUpdate area: " + e.toString() + "<br>");
            } finally {
                try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
                rs = null;
                try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
                ps = null;
            }// try delete          
        } // if (delete)
        // ************** /DELETE **************
        // ************** EDIT **************
        // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
        if (isDefined(action) && "edit".equals(action)){
            try {
                ps = connection.prepareStatement("UPDATE sit_sales"
                                             + "  SET date_of_sale = TO_DATE(?, 'mm/dd/yyyy'),"
                                             + "        model_year = ?,"
                                             + "        make = ?,"
                                             + "        vin_serial_no = ?, "
                                             + "        sale_type = ?,"
                                             + "        purchaser_name = ?,"
                                             + "        sales_price = ?,"
                                             + "        tax_amount = ?,"
                                             + "        input_date = TO_DATE(?, 'mm/dd/yyyy'),"
                                             + "        chngdate = sysdate,"
                                             + "        opercode = decode(opercode,'LOAD','LOAD',UPPER(?))"
                                             + "  WHERE year = ?"
                                             + "        and month = ?"
                                             + "        and client_id = ?"
                                             + "        and can = ?"
                                             + "        and sales_seq = ?");
                ps.setString(1, date_of_sale);
                ps.setString(2, model_year);
                ps.setString(3, make);
                ps.setString(4, vin_serial_no);
                ps.setString(5, sale_type);
                ps.setString(6, purchaser_name);
                ps.setString(7, sales_price);
                ps.setString(8, tax_amount);
                ps.setString(9, input_date);
                ps.setString(10, sitUser.getUserName() );
                ps.setString(11, year);
                ps.setString(12, month);
                ps.setString(13, client_id);
                ps.setString(14, can);
                ps.setString(15, sales_seq);

                if (ps.executeUpdate() > 0){
                    sb.append("update success\r\n");
                } else {
                    sb.append("update failure\r\n");
                }
   
            } catch (Exception e) { sb.append("<br>Exception in executeUpdate area: " + e.toString() + "<br>");
            } finally {
                try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
                rs = null;
                try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
                ps = null;
            }// try edit          
        } // if (edit)
        // ************** /EDIT **************
        // ************** NEW **************
        if (isDefined(action) && "new".equals(action)){
            try { // get new sales_seq number
                ps = connection.prepareStatement("select sit_sales_seq.nextval from dual");
//                                                "SELECT nvl(max(sales_seq)+1, 1) "
//                                             + "  FROM sit_sales "
//                                             + "  WHERE year = ? AND month = ? AND client_id = ? AND can = ? ");
//                ps.setString(1, year);
//                ps.setString(2, month);
//                ps.setString(3, client_id);
//                ps.setString(4, can);
                rs = ps.executeQuery();
                rs.next();
                sales_seq = rs.getString(1);
                
                sb.append("sales_seq is " + sales_seq + "\r\n");

            } catch (Exception e) { sb.append("<br>Exception in executeUpdate area: " + e.toString() + "<br>");
            } finally {
                try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
                rs = null;
                try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
                ps = null;
            }// try get new sales_seq number     


/* 
    see if report seq is there for month/year/client/can
        if not, get new value and create initialized record
        if yes, get current value
*/

            //try { // see if report_seq is already there
            //    ps = connection.prepareStatement("SELECT report_seq FROM sit_sales_master WHERE year=? and month=? and client_id=? AND can=? ");
            //    ps.setString(1, year);
            //    ps.setString(2, month);
            //    ps.setString(3, client_id);
            //    ps.setString(4, can);
            //    rs = ps.executeQuery();
            //    report_seq_exists = rs.next();                  
            //    report_seq = report_seq_exists ? rs.getString(1) : "1" ;
            //    
            //    sb.append("\r\nsee if it's there: report_seq_exists: " + report_seq_exists + ", report_seq: " + report_seq);
//
            //} catch (Exception e) { sb.append("<br>Exception in executeUpdate area: " + e.toString() + "<br>");
            //} finally {
            //    try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
            //    rs = null;
            //    try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
            //    ps = null;
            //}// try edit                          

            //if (!report_seq_exists){ // Create new master record. Need to get max(re)
            //    try { // create new record
            //            ps = connection.prepareStatement("insert into sit_sales_master (client_id, can, year, month, report_seq, report_status, dealer_type, form_name, //pending_payment, opercode, chngdate) VALUES (?, ?, ?, ?, ?, 'O', ?, ?, 'N', 'ACT', sysdate) ");
//
            //            ps.setString(1, client_id);
            //            ps.setString(2, can);
            //            ps.setString(3, year);
            //            ps.setString(4, month);
            //            ps.setString(5, report_seq);
            //            ps.setString(6, dealer_type);
            //            ps.setString(7, form_name);
            //            ps.executeUpdate();
            //            
            //            sb.append("insert new sales master record");
//
            //    } catch (Exception e) { sb.append("Exception in create new record area: " + e.toString() + "<br>");
            //    } finally {
            //        try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
            //        rs = null;
            //        try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
            //        ps = null;
            //    }// try create new record  
            //} 
            
            // PRC 198408 - 08/07/2018 - login useranme will be stored into column 'opercode' for any inserts and updates. If the opercode value is 'LOAD', nothing will change
            try { // write new sales record
                ps = connection.prepareStatement("INSERT INTO sit_sales("
                                             + "    can, date_of_sale,"
                                             + "    model_year, make,"
                                             + "    vin_serial_no, sale_type,"
                                             + "    purchaser_name, sales_price,"
                                             + "    tax_amount, client_id, "
                                             + "    year, month,"
                                             + "    sales_seq, status,"
                                             + "    report_seq, uptv_factor,"
                                             + "    pending_payment, input_date,"
                                             + "    opercode, chngdate)"
                                             + " VALUES (?,TO_DATE(?, 'mm/dd/yyyy'),?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,TO_DATE(?, 'mm/dd/yyyy'), UPPER(?), CURRENT_TIMESTAMP) ");
                ps.setString(1, can);
                ps.setString(2, date_of_sale);
                ps.setString(3, model_year);
                ps.setString(4, make);
                ps.setString(5, vin_serial_no);
                ps.setString(6, sale_type);
                ps.setString(7, purchaser_name);
                ps.setString(8, sales_price);
                ps.setString(9, tax_amount);
                ps.setString(10, client_id);
                ps.setString(11, year);
                ps.setString(12, month);
                ps.setString(13, sales_seq);
                ps.setString(14, status);
                ps.setString(15, report_sequence);
                ps.setString(16, uptv_factor);
                ps.setString(17, pending_payment);
                ps.setString(18, input_date);
                ps.setString(19, sitUser.getUserName() );

                if (ps.executeUpdate() > 0){ //ps.executeUpdate()
                    sb.append("insert success\r\n");
                } else {
                    sb.append("insert failure\r\n");
                }

            } catch (Exception e) { sb.append("Exception in executeUpdate area: " + e.toString() + "<br>");
            } finally {
                try { if (rs != null) rs.close(); } catch (Exception e) { sb.append("Exception in first rs.close: " + e.toString() + "<br>");}
                rs = null;
                try {if (ps != null) ps.close(); } catch (Exception e) {sb.append("Exception in first ps.close: " + e.toString() + "<br>"); }
                ps = null;
            }// try insert          
        } // if (new)
        // ************** /NEW **************
    } catch (Exception e) { sb.append( "Exception in outer catch: " + e.toString() + "<br>" );
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception e) {sb.append("Exception in second rs.close: " + e.toString() + "<br>"); }
        rs = null;
        try { if (ps != null) ps.close(); } catch (Exception e) { sb.append("Exception in second ps.close: " + e.toString() + "<br>");}
        ps = null;
        if (connection != null) {
            try { connection.close(); } catch (Exception e) { sb.append("Exception in conn.close: " + e.toString());}
            connection = null;
        }
    }//outer try
    sb.append("\r\naction = " + action + "\r\n");
    sb.append("\r\n\r\ncan = " + can + ", date_of_sale = " + date_of_sale + ", model_year = " + model_year + ", make = " + make 
          + ", vin_serial_no = " + vin_serial_no + ", sale_type = " + sale_type + ", purchaser_name = " + purchaser_name 
          + ", sales_price = " + sales_price + ", tax_amount = " + tax_amount + ", client_id = " + client_id + ", year = " + year 
          + ", month = " + month + ", form_name = " + form_name + ", sales_seq = " + sales_seq + ", uptv_factor = " + uptv_factor 
          + ", pending_payment = " + pending_payment + ", input_date = " + input_date + ", status = " + status + "\r\n");
} // if can != null
%>      
<% /*sb.toString()*/ %>
