<%@ page import="java.util.*,act.util.*,java.sql.*,java.math.*,java.text.*" 
%><%--
    Chase Realtime Notification Processing
    Chase provides a notice only on transaction success. We do not receive any failure notifications.

    Up to three notification attempts are made by Chase, each 30 minutes apart. Chase expects the
    response "OK" when the notification is successfully received.

    WEB transactions
          1DealerNumber:  (1361770) (this is the TID)
         ConfirmationId:  (GALPRT000203458) | (CYFTAX000195913)
         ConvenienceFee:  (0.00)
          PaymentAmount:  (1158.17)
         PaymentChannel:  (WEB) | (WEB-TF) | (CSR-TF)
   PaymentEffectiveDate:  (20160908) | (2016-09-08)
          PaymentMethod:  (CC) | (ACH)

     ** These fields are only included in transaction file (-TF) transactions
       payer_first_name:  (Terra)
        payer_last_name:  (Bowman)
           payer_street:  (6 Stonybrook)
             payer_city:  (Angleton)
            payer_state:  (TX)
             payer_zip5:  (77515)
             payer_zip4:  ( )
     payer_phone_number:  (8324316096)
            payer_email:  (terrajb1980@yahoo.com)

--%><%!
    // We will want to define these values in a configuration file that is loaded
    // when we receive a notification. For right now these are statically defined.
    String    datasource          = "jdbc/development";
    String    vendor              = "Chase";
    String    clientId            = "7580";

    boolean   commitOnCompletion  = true;
    boolean   isManualExecution   = false;

    boolean   sendEmailNotice     = true;
    String    emailFromAddress    = "DallasSITPayment@lgbs.com";
    String    emailToAddresses    = "Scott.Shike@lgbs.com";
    String    emailSubject        = "Dallas SIT " + vendor + " Payment Postback";
%><%
	response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
	response.setHeader("Pragma", "no-cache");
	response.setHeader("Expires", "0");


    // Process the notice and send email summary of the processing
    TransactionProcessor transaction = new TransactionProcessor(new SitChaseNotice(clientId,request));

    if ( sendEmailNotice ) 
        transaction.sendEmail(request, emailFromAddress, emailToAddresses, emailSubject);

    // Flag to the calling process that we have completed
    %>OK<%

    // The trace output is for testing purposes only, it should not be included 
    // in normal operation
    if ( isManualExecution ) {
        %><hr><pre><%= transaction.trace() %></pre><%
    }

    // Exit execution. Some calling processes look for a specific return value
    // to know whether processing was successfully completed or not. We don't
    // want any additional spaces or carriage returns causing the submitting
    // process to continually trying to repost the transaction.
    if ( true ) return;
%><%!
public boolean notDefined(String val) {
    return val == null || val.length() == 0; 
}

public class TransactionProcessor {
    public TransactionProcessor() {
        format.setMinimumFractionDigits(2);
        format.setMaximumFractionDigits(2);
    }
    public TransactionProcessor(TransactionNotice notice) {
        this();
        processTransaction(notice);
    }

    TransactionData   transaction         = null;
    String            newTid              = null;
    String            updateTid           = null;

    Exception         processingException = null;

    public void processTransaction(TransactionNotice notice) {
        Connection        conn                = null;

        try {
            transaction         = null;
            newTid              = null;
            updateTid           = null;

            processingException = null;

            startTrace();
            trace("Notice received:\n" + notice.summary());

            if ( notDefined(notice.clientId) ||  notDefined(notice.account) 
                    ||  notDefined(notice.ptid)
                    ||  notice.amount <= 0 ) {
                trace("Invalid notice. Incomplete or missing data. Ignoring.");
                return;
            }

            trace("Datasource: " + datasource);
            conn = Connect.open(datasource);
            conn.setAutoCommit(false);
            trace("Database: " + Connect.getName(conn) + "/" + Connect.getUser(conn));


            trace("Searching for transaction");
            transaction = findTransaction(conn, notice);
            if ( transaction == null ) {
                // Transaction wasn't found. 
                // We can't create records for it since we don't know what the account numbers being paid are or how
                // much each account is paying.

                trace("Failed to locate transaction");

                // This is a multi-account payment. We can't create the records because we don't
                // know what accounts were used. We should never encounter this unless something
                // is very wrong.

                if ( ! notice.paymentChannel.endsWith("-TF") ) {
                    StringBuffer summaryNotice = new StringBuffer();
                    summaryNotice.append("<div style='font-size:14px;'>");

                    summaryNotice.append("<div style='font-size:14px;'>");

                    summaryNotice.append("A payment notification was received from "
                                        + vendor
                                        + " that will need to be manually addressed.<br><br>");

                    summaryNotice.append("A payment was made "
                                        + "where the reported payment amount does not match "
                                        + "what the tax payer originally specified.");

                    summaryNotice.append("</div>");
                    summaryNotice.append("<br><hr style='width:95%;'><br>\n");
                    summaryNotice.append("<i>This is the payment information received "
                                        + "from " + vendor + ":</i><pre>\n");
                    summaryNotice.append(noticeReceived(notice.account, notice.paymentDate,
                                                        notice.ptid, notice.paymentChannel,
                                                        notice.transactionMode, notice.method,
                                                        notice.amount));

                    summaryNotice.append("\n\n</pre>");

                    summaryNotice.append(String.format("<pre style='font-family:Arial;'>DateTime: %s      Database: %s      Server: %s      Client: %s\n</pre>",
                                            (new java.util.Date()).toString(),
                                            Connect.getName(conn),
                                            notice.server,
                                            notice.clientId
                                            )
                                        );

                    try {
                        trace("Sending multi-account exception Email");
                        EMail.sendHtml(emailFromAddress, emailToAddresses,
                                    emailSubject + ": Multi-account payment exception"
                                    + " - " + notice.account,
                                    summaryNotice.toString()
                                    );
                    } catch (Exception ignore) {
                        trace("Failed to send multi-account exception Email\n" + ignore.toString());
                    }
                }

                throw UNABLE_TO_CREATE_EXCEPTION;
            } else {
                // We found a matching transaction, now we will see if it needs to be updated. We
                // will only update transactions that haven't been updated previously, which means
                // we will only update records with a "SB" status.
                //
                // If the transaction has already been updated but the payer has changed 
                // we'll allow the payer to be updated if the status is still "AP".

                trace("Found: " + transaction.toString());
                if ( "SB".equals(transaction.status) ) {
                    buffer.append("<hr>");
                    buffer.append(listTransaction(conn, notice.clientId, transaction.tid));
                    buffer.append("<hr>");
                    trace("Updating existing record. TID: " + transaction.tid);
                    updateTransaction(conn, transaction.tid, notice);
                    updateTid = transaction.tid;
                    buffer.append("<hr>");
                    buffer.append(listTransaction(conn, notice.clientId, transaction.tid));
                    buffer.append("<hr>");
                } else {
                    trace("Record previously updated (" + transaction.status + ")");
                    if ( "AP".equals(transaction.status) ) {
                        if ( isDefined(notice.name) && ! notice.name.equals(transaction.name) ) {
                            trace("Updating Payer information");
                            trace("Notice (" + notice.name + ")  DB: (" + transaction.name + ")");
                            updateAddress(conn, transaction.tid, notice);
                        }
                    }
                    buffer.append("<pre>");
                    buffer.append(listTransaction(conn, notice.clientId, transaction.tid));
                    buffer.append("</pre>");
                }
            }

            if ( commitOnCompletion ) {
                conn.commit();
            } else {
                trace("Commit on completion is false, reversing any transaction changes");
                conn.rollback();
                buffer.append("<hr>");
                trace("Rollback executed. TID: " + transaction.tid);
                buffer.append("<hr>");
                buffer.append(listTransaction(conn, notice.clientId, transaction.tid));
                buffer.append("<hr>");
            }
        } catch (Exception exception) {
            processingException = exception;
            trace("Exception: " + exception.toString());
        } finally {
            if ( conn != null ) {
                try { conn.rollback(); } catch (Exception ignore) {}
                try { conn.setAutoCommit(true); } catch (Exception ignore) {}
                try { conn.close(); } catch (Exception ignore) {}
            }
        }
    }

    public void sendEmail(javax.servlet.http.HttpServletRequest request,
                String emailFromAddress, String emailToAddresses, String emailSubject) {

        // This block is used to record the transaction information. Long term we will want
        // to log this instead of sending an email.
        try {
            StringBuffer message = new StringBuffer();
            StringBuffer parameterLink = new StringBuffer();
            StringBuffer parameterList = new StringBuffer();

            message.append(
                      "Date: " + (new java.util.Date()).toString() + "<br>"
                    + "Server: " + java.net.InetAddress.getLocalHost() + "<br>"
                    );
            if ( request != null ) {
                message.append(
                        "Page: " + request.getRequestURL() + "<br>"
                        + "From IP Addr:  " + request.getRemoteAddr() 
                            + (request.getRemoteAddr().equals(request.getRemoteHost()) ? "" : " &ndash; " + request.getRemoteHost()) + "<br>" 
                        );
            }
            String databaseName = "*unknown*";
            try {
                databaseName = Connect.getName(datasource);
            } catch (Exception e) {
            }

            message.append(
                    "Database: " + datasource + "  (" + databaseName + ")<br>" 
                    );
            if ( processingException != null ) {
                message.append("<h5 style='margin-bottom: 3px;text-decoration: underline;'> Processing Exception </h5><pre>");
                message.append(processingException.toString());
                message.append("</pre><br>\n<br>\n");
            } else if ( newTid != null ) {
                message.append("<h4> New record created: " + newTid + " </h4>");
            } else if ( updateTid != null ) {
                message.append("<h4> Existing record update: " + updateTid + " </h4>");
            } else {
                message.append("<h4> No change to existing record: " + (transaction != null ? transaction.tid : "UNKNOWN") + " </h4>");
            }

            message.append("<h5 style='margin-bottom: 3px;text-decoration: underline;'> Execution Trace </h5><pre>");
            message.append(trace());
            message.append("</pre>");

            if ( request != null ) {
                Map parameterMap = request.getParameterMap();
                String [] keys = (String [])parameterMap.keySet().toArray(new String[0]);
                Arrays.sort(keys);

                parameterList.append("<h5 style='margin-bottom: 3px;text-decoration: underline;'> Parameters Received </h5><pre>");
                if ( keys.length == 0 ) {
                    parameterList.append("**None**\n");
                } else {
                    for ( int i=0; i < keys.length; i++ ) {
                        parameterList.append(keys[i] + ": (" + request.getParameter(keys[i]) + ")\n");

                        parameterLink.append(keys[i] + "=" + request.getParameter(keys[i]));
                        if ( i < keys.length-1 ) parameterLink.append("&");
                    }
                }
                parameterList.append("</pre><br>\n");

                message.append(parameterList.toString());
                message.append(request.getRequestURL() + "?" + parameterLink.toString());
            }

            if ( isManualExecution ) {
                buffer.append(message.toString());
            } else {
                trace("Sent EMail:\n"+message.toString());
                act.util.EMail.sendHtml(emailFromAddress, emailToAddresses,
                    emailSubject + (processingException != null ? " - ERROR" : ""),
                    message.toString() 
                    );
            }
        } catch (Exception ignore) {
        }
    }



	public Exception UPDATE_FAILURE_EXCEPTION = new Exception("Failed to update transaction");
	public Exception UNABLE_TO_CREATE_EXCEPTION = new Exception("Unable to create a multi-account transaction");

    public boolean isDefined(String val) {
        return val != null && val.length() > 0; 
    }
    public boolean notDefined(String val) {
        return val == null || val.length() == 0; 
    }

	public String nvl(String val) { 
        return (val == null ? "" : val); 
    }

	public String nvl(String val, String def) { 
        return (val == null ? def : val); 
    }

	public double nvl(String val, double def) { try { return Double.parseDouble(val); } catch (Exception ignore) {} return def; }
	public int    nvl(String val, int def)    { try { return Integer.parseInt(val); } catch (Exception ignore) {} return def; }

	StringBuffer buffer = new StringBuffer();

	public void startTrace() {
        buffer.setLength(0); 
    }

	public String trace() { 
        return buffer.toString(); 
    }

	public void trace(String message) {
		buffer.append((new java.util.Date()).toString() + ": " + message + "\n");
	}

    public void extend(Exception exception, String message) throws Exception {
        throw (Exception) exception.getClass().getConstructor(new Class[]{(new String()).getClass()}).newInstance((Object[])(new String[]{message + ". " + exception.getMessage()}));
    }

    java.text.NumberFormat format = java.text.DecimalFormat.getInstance();

	public TransactionData findTransaction(Connection conn, TransactionNotice notice) throws Exception {
        if ( notDefined(notice.account) ) return null;

        return findTransactionByTID(conn, notice);
    }

	public TransactionData findTransactionByTID(Connection conn, TransactionNotice notice) 
            throws Exception {
		PreparedStatement ps = null;
		ResultSet rs = null;
		TransactionData transaction = null;

		try { 
			ps = conn.prepareStatement(
					"select tid, status, ptid, name "
					+ " from sit_epay "
                    + " where client_id=? and tid=? "
                    + "   and to_date(?,'yyyymmdd') between paymentdate-10 and paymentdate+8 "
					+ "   and (ptid=? or ptid is null) "
					+ "   and status in ('SB','??','AP','RT') "
					+ "   and amount=?");

			ps.setString(1,notice.clientId);
			ps.setString(2,notice.account);
			ps.setString(3,notice.paymentDate);
			ps.setString(4,notice.ptid);
			ps.setDouble(5,notice.amount);
			rs = ps.executeQuery();
			if ( rs.next() ) {
				transaction = new TransactionData(rs.getString("tid"),rs.getString("status"),
                                                    rs.getString("ptid"), rs.getString("name"));
            }
		} catch (Exception exception) {
			extend(exception, "Search for matching TID transaction");
		} finally {
			try { rs.close(); } catch (Exception ignore) {}
			try { ps.close(); } catch (Exception ignore) {}
		}

		return transaction;
	}

    public String listTransaction(Connection conn, String clientId, String tid) throws Exception {
        PreparedStatement ps               = null;
        ResultSet         rs               = null;

        StringBuffer      buffer           = new StringBuffer();

        try {
            buffer.append(
                String.format("%-8s %-8s %-14s  %2s %2s  %-21s %9s  %s\n",
                        "TID",
                        "Seq",
                        "Payment-Date",
                        "",
                        "",
                        "Account",
                        "Year",
                        "Month",
                        "Amount",
                        "PTID"));
            buffer.append(
                String.format("%-8s %-14s  %2s %2s  %-21s %4s %9s %9s  %s\n",
                        "--------",
                        "--------------",
                        "--",
                        "--",
                        "---------------------",
                        "----",
                        "---------",
                        "---------",
                        "----------"));
            ps = conn.prepareStatement(
                      "select epay.tid, epay.status, epay.paytype as \"method\", "
                    + "        epay.ptid, epay.name, "
                    + "        dtl.can, dtl.year, nvl(dtl.month,0) as \"Month\", dtl.amount, "
                    + "        to_char(epay.paymentDate,'mm/dd/yy hh24:mi') as \"paymentDate\" "
                    + "  from sit_epay epay "
                    + "  join sit_epaydtl dtl on (dtl.client_id=epay.client_id and dtl.tid=epay.tid) "
                    + " where epay.client_id=? and epay.tid=? "
                    + " order by dtl.epay_sequence"
                    );

            ps.setString(1,clientId);
            ps.setString(2,tid);
            rs = ps.executeQuery();
            int rows = 0;
            double amount = 0.0;
            while ( rs.next() ) {
                rows++;
                buffer.append(
                    String.format("%-8s %-8s %-14s  %2s %2s  %-21s %4s %9s %9s  %-20s  %s\n",
                            rs.getString("tid"),
                            rs.getString("aid"),
                            rs.getString("paymentDate"),
                            rs.getString("status"),
                            rs.getString("method"),
                            rs.getString("account"),
                            rs.getString("year"),
                            getMonthName(rs.getInt("month")),
                            format.format(rs.getDouble("amount")),
                            nvl(rs.getString("vtid")),
                            nvl(rs.getString("name"))
                            )
                            );
                amount += Double.parseDouble(rs.getString("amount"));
            }
            if ( rows > 1 ) {
                buffer.append(String.format("%63s%9s\n","","---------"));
                buffer.append(String.format("%62s %9s\n","Total:",format.format(amount)));
            }
        } catch (Exception exception) {
            throw exception;
        } finally {
            try { rs.close(); } catch (Exception ignore) {} rs = null;
            try { ps.close(); } catch (Exception ignore) {} ps = null;
        }

        return buffer.toString();
    }

    public String getMonthName(int month) {
        String [] monthNames = new String[] {
                                    "",
                                    "January", "February", "March", "April", "May",
                                    "June", "July", "August", "September", "October",
                                    "November", "December"
                                    };
        if ( month < 0 || month > monthNames.length-1 ) return "";
        return monthNames[month];
    }

	public void updateTransaction(Connection conn, String tid, TransactionNotice notice) throws Exception {
		PreparedStatement ps = null;

		try { 
			ps = conn.prepareStatement(
					  "update credit_card_data "
					+ " set status='AP', ptid=?, paytype=?, "
					+ "     name=nvl(?,name), address=nvl(?,address), "
                    + "     city=nvl(?,city), state=nvl(?,state), zipcode=nvl(?,zipcode), "
                    + "     country=nvl(?,country), "
                    + "     phone=nvl(?,phone), email=nvl(?,email) "
					+ " where client_id=? and transid=?"
					);
			ps.setString(1,notice.ptid);
			ps.setString(2,notice.method);

			ps.setString(3,notice.name);
			ps.setString(4,notice.address);
			ps.setString(5,notice.city);
			ps.setString(6,notice.state);
			ps.setString(7,notice.zip);
			ps.setString(8,notice.country);
			ps.setString(9,notice.phone);
			ps.setString(10,notice.email);

			ps.setString(11,notice.clientId);
			ps.setString(12,tid);

			int rows = ps.executeUpdate();
			if ( rows == 0 ) throw UPDATE_FAILURE_EXCEPTION;
		} catch (Exception exception) {
			extend(exception, "Update transaction record");
		} finally {
			try { ps.close(); } catch (Exception ignore) {}
		}
	}

	public void updateAddress(Connection conn, String tid, TransactionNotice notice) throws Exception {
		PreparedStatement ps = null;

		try { 
			ps = conn.prepareStatement(
					  "update sit_epay "
					+ " set name=nvl(?,name), address=nvl(?,address), "
                    + "     city=nvl(?,city), state=nvl(?,state), zipcode=nvl(?,zipcode), "
                    + "     country=nvl(?,country), "
                    + "     phone=nvl(?,phone), email=nvl(?,email) "
					+ " where client_id=? and tid=?"
					);

            ps.setString(1,notice.name);
			ps.setString(2,notice.address);
			ps.setString(3,notice.city);
			ps.setString(4,notice.state);
			ps.setString(5,notice.zip);
			ps.setString(6,notice.country);
			ps.setString(7,notice.phone);
			ps.setString(8,notice.email);

			ps.setString(9,notice.clientId);
			ps.setString(10,tid);

			int rows = ps.executeUpdate();
			if ( rows == 0 ) throw UPDATE_FAILURE_EXCEPTION;
		} catch (Exception exception) {
			extend(exception, "Update transaction record");
		} finally {
			try { ps.close(); } catch (Exception ignore) {}
		}
	}

	public String getNextTid(Connection conn) throws Exception {
		PreparedStatement ps = null;
		ResultSet rs = null;
		String tid = null;

		try { 
			ps = conn.prepareStatement("select sit_epay_sequence.nextval as \"tid\" from dual");
			rs = ps.executeQuery();
			if ( rs.next() ) {
				tid = rs.getString("tid");
			}
		} catch (Exception exception) {
			extend(exception,"Retrieve next TID value");
		} finally {
			try { rs.close(); } catch (Exception ignore) {}
			try { ps.close(); } catch (Exception ignore) {}
		}

		return tid;
	}

    // ----------------------------------------------------------------------------
    // Summary report of a specific transaction (by TID)

    /**Returns a formatted summary report of the specified transaction information
     * @param tid        transaction ID
     * @param dateTime   transaction date/time
     * @param ptid       processor transaction ID 
     * @param channel    payment channel, usually WEB or ADMIN
     * @param method     payment method, usually CC or ACH
     * @param amount     payment amount
     * @param mode       payment mode
     * @return summary report of the transaction
     * @throws Exception if an error occurs retrieving the transaction data
     */
    String noticeReceived(String tid, String dateTime, String ptid,
                            String channel, String mode, String method,
                            double amount
                            ) {
        StringBuffer buffer = new StringBuffer();
        buffer.append(String.format("%-11s %-21s  %-22s %-8s %-9s %-5s  %10s\n",
                                    "TID",
                                    "DateTime",
                                    "PTID",
                                    "Channel",
                                    "Mode",
                                    "Type",
                                    "Amount"
                                    )
                    );
        buffer.append(String.format("%-11s %-21s  %-22s %-8s %-9s %-5s  %10s\n",
                                    nvl(tid),
                                    nvl(dateTime),
                                    nvl(ptid),
                                    nvl(channel),
                                    nvl(mode),
                                    nvl(method),
                                    (new DecimalFormat("###,##0.00")).format(amount)
                                    )
                    );
        return buffer.toString();
    }

    /**Returns a summary report of a specific transaction
     * @param datasource database to connect to retrieve transaction
     * @param clientId   transaction client ID
     * @param tid        transaction ID to report
     * @return summary report of the transaction
     * @throws Exception if an error occurs retrieving the transaction data
     */
    String tidReport(String datasource, String clientId, String tid) throws Exception {
        Connection  conn   = null;
        String      report = null;

        try {
            conn = Connect.open(datasource);
            report = tidReport(conn, clientId, tid);
        } catch (Exception e) {
            //throw e;
            return e.toString();
        } finally {
            try { conn.close(); } catch (Exception e) {}
        }

        return report;
    }

    /**Returns a summary report of a specific transaction
     * @param connection database connection to retrieve transaction
     * @param clientId   transaction client ID
     * @param tid        transaction ID to report
     * @return summary report of the transaction
     * @throws Exception if an error occurs retrieving the transaction data
     */
    String tidReport(Connection conn, String clientId, String tid) throws Exception {
        PreparedStatement   ps              = null;
        ResultSet           rs              = null;
        String              status          = null;
        StringBuffer        buffer          = new StringBuffer();
        BigDecimal          totalExpected   = new BigDecimal("0.00");

        try {
            ps = conn.prepareStatement(
                              "select  case when transid=credit_sequence then 'TID'||transid "
                            + "            else '' "
                            + "            end as \"TID\", "
                            + "        case when transid=credit_sequence then to_char(chngdate,'MON DD, YYYY HH:MI AM') "
                            + "            else '' "
                            + "            end as \"DateTime\", "
                            + "        case when transid=credit_sequence then substr(anameline1,0,22) "
                            + "            else '' "
                            + "            end as \"Payer\", "
                            + "        credit_sequence as \"SID\", "
                            + "        case when length(can) > 16 then substr(can,0,13)||'...' "
                            + "            else can "
                            + "            end as \"Account\", "
                            + "        to_char(ppamount,'99,990.00') as \"Amount\", "
                            + "        case when ppstatus='SB' then 'Pending' "
                            + "             when ppstatus='??' then 'Rejected' "
                            + "             when ppstatus='AP' then 'Approved' "
                            + "             when ppstatus='RT' and (paidflag is null or paidflag!='Y') then 'Approved' "
                            + "             when ppstatus='RT' and paidflag='Y' then 'Posted' "
                            + "             else ppstatus "
                            + "             end as \"status\", "
                            + "             year as \"year\" "
                            + "  from credit_card_data c "
                            + " where client_id=? and transid=? "
                            + "   and ppstatus in ('SB','??','AP','RT') "
                            + " order by transid, credit_sequence "
                            );
            ps.setString(1, clientId);
            ps.setString(2, tid.replaceAll("TID",""));

            rs = ps.executeQuery();
            if ( ! rs.isBeforeFirst() ) throw new NoSuchElementException("No records found for " + tid);

            buffer.append(String.format("%-11s %-21s  %-22s %-8s %-16s %10s\n",
                                        "TID",
                                        "DateTime",
                                        "Payer Name",
                                        "SID",
                                        "Account",
                                        "Amount"
                                        )
                        );

            boolean includeYearColumn = false;
            int rows = 0;
            while ( rs.next() ) {
                rows++;
                status = nvl(rs.getString("status"));
                buffer.append(String.format("%-11s %-21s  %-22s %-8s %-16s %10s",
                                            nvl(rs.getString("TID")),
                                            nvl(rs.getString("DateTime")),
                                            nvl(rs.getString("Payer")),
                                            nvl(rs.getString("SID")),
                                            nvl(rs.getString("Account")),
                                            nvl(rs.getString("Amount"))
                                            )
                            );
                if ( isDefined(rs.getString("Year")) ) {
                    includeYearColumn = true;
                    buffer.append("  " + rs.getString("Year"));
                }
                buffer.append("\n");
                totalExpected = totalExpected.add(new BigDecimal(rs.getString("Amount").replaceAll(",","").trim()));
            }
            if ( includeYearColumn ) {
                buffer.insert(buffer.indexOf("\n"),"  Year");
            }

            buffer.append(String.format("\n%-11s %-21s  %22s %-8s %16s %10s\n",
                                        "",
                                        "Status: " + status,
                                        "Accounts:",
                                        ""+rows,
                                        "Total:",
                                        (new DecimalFormat("###,##0.00")).format(totalExpected.doubleValue())
                                        )
                        );
        } catch (Exception e) {
            throw e;
        } finally {
            try { rs.close(); } catch (Exception e) {}
            try { ps.close(); } catch (Exception e) {}
        }

        return buffer.toString();
    }

}

public class TransactionData {
    public TransactionData() {};
    public TransactionData(String tid, String status, String ptid) {
        this.tid = tid;
        this.status = status;
        this.ptid = ptid;
    };
    public TransactionData(String tid, String status, String ptid, String name) {
        this.tid = tid;
        this.status = status;
        this.ptid = ptid;
        this.name = name;
    };
    public String tid = null;
    public String status = null;
    public String ptid = null;
    public String name = null;

    public String toString() {
        return "TID: " + tid + "  PTID: " + ptid + "  Status: " + status;
    }
}

// The long term goal is to have this as an abstract class with each
// client implementing it with the defined "vendor" and request parameter management
// We can't do that yet because we can't extend inner classes within a JSP file

public class TransactionNotice {
    public TransactionNotice() {}

/*******
    Admin																			
    DateTime	Host	Page	IP Addr	DSN	DB Name														

    Payment																			
    Client	TID	Source	SourceId	Vendor	PTID	Note	Status	Reason	PayDate	PayType	PayRef	Amount	Fee	Total	AuthCode	Reference	Channel	Mode	

    Settlement																			
    ID	Date	Ref																	

    Payer																			
    Name	Address	City	State	Zip	Country	Phone	Email												

    Line Item																			
    Client	TID	Seq	PTID	Status	Reference	Can	Owner 	Year	Taxunit	Amount									
********/

																				
    public String    server            = "";
    public String    contextPath       = "";
    public String    servletPath       = "";
    public String    remoteAddr        = "";
    public String    remoteHost        = "";

    public String    vendor            = "Unknown";

	public String    clientId          = null;
	public String    account           = null;
	public String    ownerNo           = null;

    public String    transactionMode   = null;
	public String    paymentChannel    = null;
	public String    ptid              = null;
	public String    paymentDate       = null;
	public String    method            = null;
	public double    amount            = 0.0;

    public String    name              = null;
    public String    address           = null;
    public String    city              = null;
    public String    state             = null;
    public String    zip               = null;
    public String    country           = null;

    public String    phone             = null;
    public String    email             = null;

    public String summary() {
        return "Vendor: (" + this.vendor + ")  Client: (" + clientId + ")  Account: (" + account + ")  Amount: (" + amount + ")  "
            + "PTID: (" + ptid + ")  Date: (" + paymentDate + ")";
    }

    public String maxLen(String value, int length) {
        if ( value != null && value.length() > length ) 
            value = value.substring(0, length);
        return value;
    }

    public TransactionNotice setAccount(String clientId, String account, String ownerNo) {
        this.clientId = clientId;
        this.account  = account;
        this.ownerNo  = ownerNo;

        return this;
    }

    public TransactionNotice setPayment(String vendor, String paymentChannel, String ptid, String paymentDate, String method, double amount) {
        this.vendor         = vendor;
        this.paymentChannel = paymentChannel;
        this.ptid           = ptid;
        this.paymentDate    = paymentDate;
        this.method         = ("EC".equals(method) || "ACH".equals(method) ? "EC" : "CC");
        this.amount         = Math.max(amount,0.0);

        return this;
    }
    public TransactionNotice setPayer(String name, String address, String city, String state, String zip, String country) {
        this.name           = maxLen(name,40);
        this.address        = maxLen(address,40);
        this.city           = maxLen(city,24);
        this.state          = maxLen(state,2);
        this.zip            = maxLen(zip,12);
        this.country        = maxLen(country,40);

        return this;
    }
    public TransactionNotice setContact(String phone, String email) {
        this.phone          = maxLen(phone,20);
        this.email          = maxLen(email,60);

        return this;
    }

    public TransactionNotice setRequestContext(javax.servlet.http.HttpServletRequest request) {
        return setRequestContext(request.getServerName(),
                                request.getContextPath(), request.getServletPath(),
                                request.getRemoteAddr(), request.getRemoteHost());
    }

    public TransactionNotice setRequestContext(String server, 
                                               String contextPath, String servletPath,
                                               String remoteAddr, String remoteHost) {
        this.server         = server;
        this.contextPath    = contextPath;
        this.servletPath    = servletPath;
        this.remoteAddr     = remoteAddr;
        this.remoteHost     = remoteHost;

        return this;
    }

	public String nvl(String val) { 
        return (val == null ? "" : val); 
    }
	public String nvl(String val, String def) { 
        return (val == null ? def : val); 
    }

	public double nvl(String val, double def) { try { return Double.parseDouble(val); } catch (Exception ignore) {} return def; }
	public int    nvl(String val, int def)    { try { return Integer.parseInt(val); } catch (Exception ignore) {} return def; }
}


public class SitChaseNotice extends TransactionNotice {
    public SitChaseNotice() {}
    public SitChaseNotice(String client, javax.servlet.http.HttpServletRequest request) {

        clientId          = nvl(client);
        account           = nvl(request.getParameter("1DealerNumber")).trim();

        transactionMode   = nvl(request.getParameter("TransactionMode"));
        paymentChannel    = nvl(request.getParameter("PaymentChannel"));
        ptid              = nvl(request.getParameter("ConfirmationId"));
        paymentDate       = nvl(request.getParameter("PaymentEffectiveDate")).replaceAll("-","");
        method            = ("ACH".equals(nvl(request.getParameter("PaymentMethod"))) ? "EC" : "CC");
        amount            = nvl(request.getParameter("PaymentAmount"),0.0);

        name              = (nvl(request.getParameter("payer_first_name")) + " " +  nvl(request.getParameter("payer_last_name"))).trim();
        address           = nvl(request.getParameter("payer_street"));
        city              = nvl(request.getParameter("payer_city"));
        state             = nvl(request.getParameter("payer_state"));
        zip               = (nvl(request.getParameter("payer_zip5")) + nvl(request.getParameter("payer_zip4"))).trim();
        country           = null;
        phone             = nvl(request.getParameter("payer_phone_number"));
        email             = nvl(request.getParameter("payer_email"));

        this.setRequestContext(request)
            .setAccount(clientId, account, ownerNo)
            .setPayment(vendor, paymentChannel, ptid, paymentDate, method, amount)
            .setPayer(name, address, city, state, zip, country)
            .setContact(phone, email);
    }
    public String vendor = "Chase";
}

%><!doctype html>
<html>
<head>
</head>
<body>
</body>
</html>
