<%@ page import="java.util.*,java.io.*,java.sql.*,java.math.*,act.util.*,java.text.*,act.sit.reports.*, act.sit.SITAccount"
%><%--
    DN - 10/30/2018 - PRC 208888
        Use global_codeset to control the tempUrl
--%><%!
    StringBuffer buffer = new StringBuffer();
%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");
    response.setHeader("Access-Control-Allow-Origin","*");

    String      clientId            = (String) session.getAttribute("WEBPAY-Payment-clientId");
    String      datasource          = (String) session.getAttribute("WEBPAY-Payment-dataSource");
    SITAccount  sitAccount          = (SITAccount) session.getAttribute("sitAccount");
    boolean     showInformation     = false;
    String      webDir              = (String)session.getAttribute("WEB_DIR");



    Report report = null;
    buffer.setLength(0);
    try {
        Payer payer = identifyPayer(request);
        Account[] accounts = identifyAccounts(clientId, request);
        if ( accounts == null || accounts.length == 0 ) throw new Exception("No payment accounts specified");


        double totalAccountPayments = calculateTotalPayment(accounts);
        double totalPaymentAmount = nvl(request.getParameter("total"),0.0);

        String paymentMethod = nvl(request.getParameter("method"),"").toUpperCase(); // OT for OTHER, or OUTSIDE TRANSACTION - take your pick

        if ( showInformation ) {
            %><style>h3 { margin-bottom: 0px; } </style><%
            %><pre><h3>Payer:</h3><%= payer.toString() %></pre><%
            %><pre><hr><h3>Accounts:</h3><%= accounts[0].toString(accounts) %></pre><%

            %><li> Method of Payment: <%= paymentMethod %> </li><%
            %><li> Sum of Account Payments: <%= NumberFormat.getCurrencyInstance().format(totalAccountPayments) %> </li><%
            %><li> Reported Total Payment:  <%= NumberFormat.getCurrencyInstance().format(totalPaymentAmount) %> </li><%
            %><li> Payment Amounts Match:   <%= (totalPaymentAmount == totalAccountPayments) %> </li><%

            //return;
        }

        if ( totalPaymentAmount != totalAccountPayments ) throw new Exception("Incorrect payment total");

        Transaction transaction = createTransaction(datasource, clientId, paymentMethod, totalPaymentAmount, payer, accounts);
        String tid = transaction.tid;
        String referenceDate = null;

        // Create the pay-by-mail report
        buffer.append(String.format("Creating report: %s  %s  %s\n",clientId, tid, datasource));
        report = SITPayByMail.initialContext(clientId, tid)
                                    .setReportContextPath("/"+((webDir!= null && webDir.length()>0)? webDir:sitAccount.WEB_DIR))
                                    .create(datasource);
        String reportURL = report.getReportURI();

        if ( report.wasSuccessful() )
        {
            %>{ "status": "success",
                "data": {
                    "status": "success",
                    "tid":    "<%= tid %>", 
                    "detail": "Payment was successfully created",
                    "reportURL": "<%= reportURL %>",
                    "datetime": "<%= (isDefined(referenceDate) ? referenceDate : "") %>"
                    }
                }<%
        }
        else
        {
            %>{ "status": "fail",
                "data": { "detail": "Report failed to execute" }
                }<%
        }
    } catch (Exception exception) {
        String error = exception.toString().replaceAll("\\\"","\\\\\"");

        %>{ "status": "error", 
            "message": "Failed to record payment information", 
            "data" : {
                "description": "We were unable to record your payment information, please try again later", 
                "detail": "<%= error %>",
                "debug": "<%= (report == null ? "NULL object" : "Response Text: (" + report.getResponseText() + ")") %>"
                }
            }<%
    }

    if ( showInformation ) {
        %><pre><hr><%= buffer.toString() %></pre><%
    }

    if ( true ) return;
%><%!
    boolean isDefined(String val) { return val != null && val.length() > 0; }
    boolean notDefined(String val) { return val == null || val.length() == 0; }
    String nvl(String val) { return (val != null ? val : ""); }
    String nvl(String val, String def) { return (val != null ? val : def); }
    int    nvl(String val, int def) { try { return Integer.parseInt(val); } catch (Exception e) {} return def; }
    double nvl(String val, double def) { try { return Double.parseDouble(val); } catch (Exception e) {} return def; }
    DecimalFormat amountFormat = new DecimalFormat("#####0.00");
    String formatAmount(double amount) { return amountFormat.format(amount); }
%><%!
    public Payer identifyPayer(javax.servlet.http.HttpServletRequest request) {
        Payer payer = new Payer();

        payer.setPayer(request.getParameter("name"))
             .setAddress(request.getParameter("street"),
                         request.getParameter("city"),
                         request.getParameter("state"),
                         request.getParameter("zipcode"),
                         request.getParameter("country")
                        )
             .setContact(request.getParameter("phone"),
                         request.getParameter("email")
                        );

        return payer;
    }
%><%!
    public Account[] identifyAccounts(String cid, javax.servlet.http.HttpServletRequest request) {
        ArrayList accountList = new ArrayList();

        // [account]|[seq]|[year]|[month]|[amount]
        String [] parameters = request.getParameterValues("account");
        if ( parameters != null ) 
            for ( String accountParameter : parameters ) {
                String[] paymentParts = accountParameter.split("\\|");

                if ( paymentParts == null || paymentParts.length != 5 ) {
                    buffer.append("Account parameter: (" + accountParameter + ")\n");
                    buffer.append("     Parts length incorrect: " + (paymentParts == null ? "Null" : ""+paymentParts.length) + "\n");
                    continue;
                }

                double paymentAmount = nvl(paymentParts[4],0.0);
                if ( paymentAmount <= 0.0 ) continue;

                Account account = new Account();
                account.setAccount(cid,paymentParts[0])
                       .setSitReport(paymentParts[1])
                       .setSitPayment(paymentParts[2],paymentParts[3],paymentAmount);
                accountList.add(account);
                buffer.append("Added account: \n" + account.toString() + "\n");
            }

        return (Account[]) accountList.toArray(new Account[0]);
    }
%><%!
    public double calculateTotalPayment(Account[] accounts) {
        BigDecimal totalPayment = new BigDecimal(0.0,new MathContext(2));

        if ( accounts != null )
            for ( Account account : accounts ) {
                totalPayment = totalPayment.add(account.amount);
            }

        return totalPayment.doubleValue();
    }
%><%!
    public Transaction createTransaction(String datasource, 
                String cid, String method, double amount,
                Payer payer, Account[] accounts) throws Exception {
        Transaction transaction = null;

        try ( Connection conn = Connect.open(datasource); )
        {
            transaction = createTransaction(conn, cid, method, amount, payer, accounts);
        } catch (Exception exception) {
            throw exception;
        }

        return transaction;
    }
%><%!
    public Transaction createTransaction(Connection conn, 
                String cid, String method, double amount,
                Payer payer, Account[] accounts) throws Exception {
        String tid = null;
        String atid = null;

        try (
            PreparedStatement ps = conn.prepareStatement(
                                                      "insert into sit_epay ( "
                                                    + "    client_id, tid, source, sourceId, vendor, status, "
                                                    + "    paymentdate, paymode, paytype, amount, "
                                                    + "    name, address, city, state, zipcode, country, phone, email, "
                                                    + "    atid ) "
                                                    + "values ( "
                                                    + "    ?, ?, 'WEB', 'Pay By Mail', '', 'SB', "
                                                    + "    sysdate, null, ?, ?, "
                                                    + "    ?, ?, ?, ?, ?, ?, ?, ?, "
                                                    + "    ? ) "
                                                    );
            CallableStatement cs = conn.prepareCall("call vit_utilities.generate_tid(p_client_id=>?, o_tid=>?, o_a_tid=>?)");
        )
        {
            buffer.append("get TID\n");
            cs.registerOutParameter(2,oracle.jdbc.OracleTypes.VARCHAR);
            cs.registerOutParameter(3,oracle.jdbc.OracleTypes.VARCHAR);
            cs.setString(1,cid);
            cs.execute();
            tid = cs.getString(2);
            atid = cs.getString(3);

            buffer.append("set sit_epay values - CID: " + cid + "  TID: " + tid + "   ATID: " + atid + "\n");
            ps.setString( 1, cid);
            ps.setString( 2, tid);
            ps.setString( 3, method);
            ps.setDouble( 4, amount);
            ps.setString( 5, payer.name);
            ps.setString( 6, payer.street);
            ps.setString( 7, payer.city);
            ps.setString( 8, payer.state);
            ps.setString( 9, payer.zipcode);
            ps.setString(10, payer.country);
            ps.setString(11, payer.phone);
            ps.setString(12, payer.email);
            ps.setString(13, atid);

            buffer.append("execute\n");
            if ( ps.executeUpdate() != 1 ) throw new Exception("Failed to create transaction record");
            buffer.append("sending to accounts\n");
            createTransactionAccounts(conn, cid, tid, accounts);
        } catch (Exception exception) {
            throw exception;
        }

        Transaction transaction = new Transaction(tid, atid);
        return transaction;
    }
    public class Transaction
    {
        public Transaction(String tid, String atid)
        {
            this.tid = tid;
            this.atid = atid;
        }
        public String tid = null;
        public String atid = null;
    }
%><%!
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
            //extend(exception,"Retrieve next TID value");
            throw exception;
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
        }

        return tid;
    }
%><%!
    public void createTransactionAccounts(Connection conn, String cid, String tid, Account[] accounts) throws Exception {
        PreparedStatement ps = null;

        try {
            buffer.append("Prepare sit_epaydtl statement\n");
            ps = conn.prepareStatement(
                              "insert into sit_epaydtl ( "
                            + "    client_id, tid, epay_sequence, ptid, status, "
                            + "    report_seq, can, year, month, amount ) "
                            + " values ( "
                            + "    ?, ?, ?, null, 'SB', "
                            + "    ?, ?, ?, ?, ? ) "
                        );

            buffer.append("setting sit_epaydtl values\n");
            ps.setString( 1, cid);
            ps.setString( 2, tid);

            int sequence = 0;
            for ( Account account : accounts ) {
                ps.setInt   ( 3, ++sequence);
            buffer.append("set account " + sequence + "\n");

                ps.setString( 4, account.report);
                ps.setString( 5, account.account);
                ps.setString( 6, account.year);
                ps.setString( 7, account.month);
                ps.setDouble( 8, account.amount.doubleValue());
            buffer.append("execute\n");
                if ( ps.executeUpdate() != 1 ) throw new Exception("Failed to create account record");
            }
            buffer.append("complete\n");
        } catch (Exception exception) {
            throw exception;
        } finally {
            try { ps.close(); } catch (Exception ignore) {}
        }

        return;
    }
%><%--
    public Payment retrieveTransaction(Connection conn, String cid, String tid) throws Exception {
        PreparedStatement ps = null;
        ResultSet         rs = null;

        try {
            ps = conn.prepareStatement(
                              "select * from sit_epay where client_id=? and tid=?"
                        );

            ps.setString( 1, cid);
            ps.setString( 2, tid);

            rs = ps.executeQuery();
            if ( ! rs.beforeFirst() ) throw new Exception("Transaction not found");

            payment = new Payment();
            payment.client          = cid;
            payment.tid             = tid;

            payment.source          = rs.getString("source");
            payment.sourceId        = rs.getString("sourceId");
            payment.vendor          = rs.getString("vendor");
            payment.ptid            = rs.getString("ptid");

            payment.note            = rs.getString("note");
            payment.status          = rs.getString("status");
            payment.reason          = rs.getString("reason");

            payment.paymentDate     = rs.getString("paymentDate");
            payment.paymode         = rs.getString("paymode");
            payment.payref          = rs.getString("payref");

            payment.amount          = Double.parseDouble(rs.getString("amount"));

            payment.reference       = rs.getString("reference");
            payment.channel         = rs.getString("channel");
            payment.mode            = rs.getString("mode");

            payment.payer           = new Payer();
            payer.setPayer(rs.getString("name"))
                 .setAddress(rs.getString("street"),
                             rs.getString("city"),
                             rs.getString("state"),
                             rs.getString("zipcode"),
                             rs.getString("country")
                            )
                 .setContact(rs.getString("phone"),
                             rs.getString("email")
                            );

        } catch (Exception exception) {
            throw exception;
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
        }

        return null;
    }
--%><%--
    //Admin
    //DateTime	Host	Page	IP Addr	DSN	DB Name

    //Settlement
    //ID	Date	Ref


    //Payment
    //Client	TID	Source	SourceId	Vendor	PTID	Note	Status	Reason
    //PayDate	PayType	PayRef	Amount	Fee	Total	AuthCode	Reference	Channel	Mode	

    public class Payment {
        public Payment() {}

        public String       client          = null;
        public String       tid             = null;
        public String       source          = null;
        public String       sourceId        = null;
        public String       vendor          = null;
        public String       ptid            = null;

        public String       note            = null;

        public String       status          = null;
        public String       reason          = null;

        public String       paymentDate     = null;
        public String       paymentMethod   = null;
        public String       methodReference = null;

        public BigDecimal   amount          = null;
        public BigDecimal   fee             = null;
        public BigDecimal   total           = null;

        public String       authCode        = null;
        public String       reference       = null;
        public String       channel         = null;
        public String       mode            = null;

        public Payer        payer           = null;

        public Account []   accounts        = null;
    }
--%><%!
    //Line Item
    //Client	TID	Seq	PTID	Status	Reference	Can	Owner 	Year	Month   Taxunit	Amount
    public class Account {
        public Account() {}

        public Account(String client, String account, String ownerNo, double amount) {
        }


        public Account setAccount(String client, String account, String ownerNo) {
            this.client     = client;
            this.account    = account;
            this.ownerNo    = ownerNo;
            return this;
        }
        public Account setAccount(String client, String account) {
            this.client     = client;
            this.account    = account;
            return this;
        }

        public Account setTransaction(String tid, String ptid, String status, String reference) {
            this.tid        = tid;
            this.ptid       = ptid;
            this.status     = status;
            this.reference  = reference;
            return this;
        }

        public Account setPayment(String year, String month, String taxunit, double amount) {
            this.year       = year;
            this.month      = month;
            this.taxunit    = taxunit;
            this.amount     = new BigDecimal(amount,context);
            return this;
        }
        public Account setPayment(double amount) {
            this.amount     = new BigDecimal(amount,context);
            return this;
        }
        public Account setSitReport(String report) {
            this.report = report;
            return this;
        }
        public Account setSitPayment(String year, String month, double amount) {
            setPayment(year, month, null, amount);
            return this;
        }
        public Account setTaxPayment(String year, String taxunit, double amount) {
            setPayment(year, null, taxunit, amount);
            return this;
        }


        MathContext  context         = new MathContext(12,java.math.RoundingMode.HALF_UP);

        public String       client          = null;
        public String       tid             = null;
        public String       sid             = null;
        public String       ptid            = null;
        public String       status          = null;
        public String       reference       = null;
        public String       account         = null;
        public String       ownerNo         = null;
        public String       year            = null;
        public String       month           = null;
        public String       taxunit         = null;
        public String       report          = null;
        public BigDecimal   amount          = null;


        public String toString() {
            //Client      TID     Seq Account     Year    Month       Amount          PTID
            //147000000   123123  123 123123123   1234    September   $10,000,000.00  GALPRT000220259
            return String.format("%-9.9s %-6.6s %-3.3s %-12.12s %-4.4s %-5.5s %15s %s\n"
                                +"%-9.9s %-6.6s %-3.3s %-12.12s %-4.4s %-5.5s %15s %s\n",
                                "Client", "TID", "Seq", "Account", "Year", "Month", "Amount", "PTID",
                                client, tid, sid, account, year, month, 
                                NumberFormat.getCurrencyInstance().format(amount.doubleValue()), ptid);
        }

        public String toString(Account[] accounts) {
            StringBuffer buffer = new StringBuffer();

            buffer.append(String.format("%-9.9s %-6.6s %-3.3s %-3.3s %-12.12s %-4.4s %-5.5s %15s %s\n",
                                "Client", "TID", "Seq", "Rpt", "Account", "Year", "Month", "Amount", "PTID"
                                ));

            for ( Account account : accounts ) {
                buffer.append(String.format("%-9.9s %-6.6s %-3.3s %-3.3s %-12.12s %-4.4s %-5.5s %15s %s\n",
                                account.client, account.tid, account.sid, account.report,
                                account.account, account.year, account.month, 
                                NumberFormat.getCurrencyInstance().format(account.amount.doubleValue()), 
                                account.ptid
                                ));
            }
            return buffer.toString();
        }
    }
%><%!
    //Payer
    //Name	Street	City	State	Zip	Country	Phone	Email
    public class Payer {
        public Payer() {}
        public Payer(String name, String street, 
                     String city, String state, String zipcode) {
            setPayer(name);
            setAddress(street, city, state, zipcode);
        }
        public Payer(String name, String street, 
                     String city, String state, String zipcode,
                     String country) {
            setPayer(name);
            setAddress(street, city, state, zipcode, country);
        }
        public Payer(String name, String street, 
                     String city, String state, String zipcode,
                     String country,
                     String phone, String email) {
            setPayer(name);
            setAddress(street, city, state, zipcode, country);
            setContact(phone, email);
        }

        public Payer setPayer(String name) {
            this.name       = name;
            return this;
        }

        public Payer setAddress(String street, 
                        String city, String state, String zipcode) {
            this.street     = street;
            this.city       = city;
            this.state      = state;
            this.zipcode    = zipcode;
            return this;
        }
        public Payer setAddress(String street, 
                        String city, String state, String zipcode,
                        String country) {
            this.street     = street;
            this.city       = city;
            this.state      = state;
            this.zipcode    = zipcode;
            this.country    = country;
            return this;
        }
        public Payer setContact(String phone, String email) {
            this.phone      = phone;
            this.email      = email;
            return this;
        }

        public String       name            = null;
        public String       street          = null;
        public String       city            = null;
        public String       state           = null;
        public String       zipcode         = null;
        public String       country         = null;
        public String       phone           = null;
        public String       email           = null;

        public String toString() {
            return String.format("%-15.15s %-15.15s %-12.12s %-5.5s %-7.7s %-7.7s %-15.15s %s\n"
                                +"%-15.15s %-15.15s %-12.12s %-5.5s %-7.7s %-7.7s %-15.15s %s\n",
                                "Name", "Street", "City", "State", "Zipcode", "Country", "Phone", "Email",
                                name, street, city, state, zipcode, country, phone, email);
        }
    }
%>
