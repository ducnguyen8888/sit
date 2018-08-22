<%@page import="java.util.Arrays"%>
<%@ include file="../_configuration.inc" %>

<%
    // general
    String pageTitle = "User Sign In"; 
    boolean forwarded = ("true".equals(request.getParameter("forwarded")))? true : false;
    String client_id = request.getParameter("client_id");
    String userid = null;
    String name = "";
    StringBuffer sb = new StringBuffer();
    StringBuffer clients = new StringBuffer();
    StringBuffer errorMessage = new StringBuffer();
    ds.clear(); // prevents ghost record from showing up after failed and then successful login
    errorMessage.append("");

    // for Dealers
    java.util.ArrayList yearsTemp = new java.util.ArrayList();
    String [] years = null;
    String nameline1 = "";
    String nameline2 = "";
    String nameline3 = "";
    String nameline4 = "";
    String city = "";
    String state = "";
    String country = "";
    String zipcode = "";
    String phone = "";
    int    theType = 0;
    String yearTemp = "";
    String prevCan  = "";
    String aprdistacc = "";
    String email = "";

    //database
    PreparedStatement ps = null;
    ResultSet rs = null;
    Connection connection = null;
%>
<%
connection = connect();
try{  
    if(request.getParameter("user") != null){
        try {          
            ps = connection.prepareStatement("select upper(ou.can), o.dealer_type, o.year, o.nameline1, o.nameline2, o.nameline3, o.nameline4, o.city, o.state, "
                                          + "        country, o.zipcode, o.phone, ou.client_id, ou.userid, name, t.aprdistacc, u.email, ou.active"
                                          + " from   sit_users u"
                                          + "   join sit_ownership_username ou on (ou.client_id = u.client_id and ou.userid = u.userid)"
                                          + "   join owner o on (o.client_id = ou.client_id and o.can = ou.can)"
                                          + "   join taxdtl t on (t.can = o.can and t.year = o.year)"
                                          + " where  upper(username) = upper(?) and upper(pin) = upper(?) and upper(u.client_id) = upper(?) and ou.active='Y'"
                                          + " order by upper(ou.can) asc, year asc, nameline1 asc");
                                          //+ " order by nameline1 asc, upper(can) asc, year desc");
            ps.setString(1, request.getParameter("user"));
            ps.setString(2, request.getParameter("pw"));// /request.getParameter("pw")
            ps.setString(3, request.getParameter("ddLogin"));
            rs = ps.executeQuery();
  
            if(rs.next()){ // first run catches initial record
                can        = rs.getString(1);
                prevCan    = rs.getString(1);
                theType    = rs.getInt(2);
                yearTemp   = rs.getString(3);
                nameline1  = rs.getString(4);
                nameline2  = rs.getString(5);
                nameline3  = rs.getString(6);
                nameline4  = rs.getString(7);
                city       = rs.getString(8);
                state      = rs.getString(9);
                country    = rs.getString(10);
                zipcode    = rs.getString(11);
                phone      = rs.getString(12);
                client_id  = rs.getString(13);
                userid     = rs.getString(14);
                name       = rs.getString(15);
                aprdistacc = rs.getString(16);
                email      = rs.getString(17);

                boolean stillOnSame = true;
                while(rs.next()) {
                    can       = rs.getString(1);
                    stillOnSame = prevCan.equals(can) ? true : false;

                    if (stillOnSame) {//still on same account, add to arraylist
                        yearsTemp.add(yearTemp);
                    } else {//different info, push old
                        yearsTemp.add(yearTemp);
                        years = (String [])yearsTemp.toArray(new String[yearsTemp.size()]);
                        ds.add(new Dealership(prevCan,theType, years, nameline1, nameline2, nameline3, nameline4, city, state, country, zipcode, phone, aprdistacc));
                        yearsTemp.clear();
                    }
                    prevCan    = can;
                    can        = rs.getString(1);
                    theType    = rs.getInt(2);
                    yearTemp   = rs.getString(3);
                    nameline1  = rs.getString(4);
                    nameline2  = rs.getString(5);
                    nameline3  = rs.getString(6);
                    nameline4  = rs.getString(7);
                    city       = rs.getString(8);
                    state      = rs.getString(9);
                    country    = rs.getString(10);
                    zipcode    = rs.getString(11);
                    phone      = rs.getString(12);
                    client_id  = rs.getString(13);
                    userid     = rs.getString(14);
                    aprdistacc = rs.getString(16);
               } //while
            }
            yearsTemp.add(yearTemp);
            years = (String [])yearsTemp.toArray(new String[yearsTemp.size()]);
            ds.add(new Dealership(prevCan,theType, years, nameline1, nameline2, nameline3, nameline4, city, state, country, zipcode, phone, aprdistacc));
            if (ds.size() == 0 ) { sb.append("<br>no records found<br>"); }
        } catch (Exception e) {
             SITLog.error(e, "\r\nProblem getting dealers in nested login.jsp\r\n");
        } finally {
            try { rs.close(); } catch (Exception e) { }
            rs = null;
            try { ps.close(); } catch (Exception e) { }
            ps = null;
        }// try get dealerships

        if (client_id != null && !"".equals(client_id)){
            if("79000000".equals(client_id)) 
                session.setAttribute("imageName", "fbc");
            else if("147000000".equals(client_id)) 
                session.setAttribute("imageName", "galveston");
            else if("94000000".equals(client_id)) 
                session.setAttribute("imageName", "elpaso");
            else if("94500000".equals(client_id)) 
                session.setAttribute("imageName", "elpaso");
            else if("2000".equals(client_id)) 
                session.setAttribute("imageName", "harris");
            else if("7580".equals(client_id)) 
                session.setAttribute("imageName", "dallas");                
            else
                session.setAttribute("imageName", "act");
            
            session.setAttribute( "client_id", client_id );
            session.setAttribute( "userid", userid );
            session.setAttribute( "username", name );
            session.setAttribute( "email", email );
            try{// get client pref
                ps = connection.prepareStatement("select nvl(sit_get_codeset_value(?,'DESCRIPTION','CLIENT','SIT_FINALIZE_ON_PAY'),'N') from dual");
                ps.setString(1, client_id);
                rs = ps.executeQuery();
                rs.next();
                session.setAttribute("finalize_on_pay", rs.getString(1));
            } catch (Exception e) {
                 SITLog.error(e, "\r\nProblem getting client_pref for login.jsp\r\n");
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }    
            if (connection != null) { // close connection before redirect
                try { connection.close(); } catch (Exception e) { }
                connection = null;
            }            
            response.sendRedirect("../dealerships.jsp");
        } else {
            errorMessage.append("User not found.<br>Please contact your tax office if you continue<br>to have problems.");
        }
    }// if user
    if(forwarded){
        String client_name = request.getParameter("client_name");
        String ddLogin = client_id;
    } else {
        if (connection != null) {//added this because I already closed the connection above for redirect but this was still trying to run
            try{// get client_id & client_name for Dropdown
                ps = connection.prepareStatement("select distinct u.client_id, c.client_name "
                                              + " from sit_users u"
                                              + " join client c on (u.client_id = c.client_id)"
                                              + " order by c.client_name");
                rs = ps.executeQuery();

                boolean isSelected = false;
                
                while (rs.next()){
                    isSelected = (rs.getString(1).equals(session.getAttribute("client_id")));
                    clients.append("<option value=\"" + rs.getString(1) + "\" " + (isSelected ? "selected" : "") + ">" + rs.getString(2) + "</option>");
                }
                
            } catch (Exception e) {
                 SITLog.error(e, "\r\nProblem getting client_id in nested login.jsp\r\n");
            } finally {
                try { rs.close(); } catch (Exception e) { }
                rs = null;
                try { ps.close(); } catch (Exception e) { }
                ps = null;
            }// try get client_id & client_name for Dropdown
        } //if (connection != null) 
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
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= pageTitle %></title>
    <meta name="description" content="Tax system for Special Inventory items">
    <meta name="author" content="Appraisal and Collection Technologies, LLC">
    <link href="../assets/css/bootstrap.css" rel="stylesheet">
    <link href="../assets/css/font-awesome.min.css" rel="stylesheet">
    <link href="../assets/css/jquery-ui.min.css" rel="stylesheet">
    <link href="../assets/css/styles.css?<%= (new java.util.Date()).getTime() %>" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
          <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
          <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->
<!-- include styles here -->
<style>
    #loginDiv { width: 1080px; }
    #login, #forgot { float:left; margin-top: 80px; margin-left: 40px; margin-right: 0px; background: #f5f5f5; border: 1px solid #d3d3d3; 
                      padding: 20px 30px; width: 400px; height: 370px; -webkit-border-radius: 10px; -moz-border-radius: 10px; border-radius: 10px; } 
    #instructions{ float:left; margin-top: 90px; margin-left: 30px; padding-left: 30px; padding-top: 20px; font-size: 1.2em; color: #005eb9; 
                   height: 350px; max-width: 420px; border-left: 1px solid #d3d3d3; } 
    .toggleText { float: left; font-size: 12px; }
    #sidebarTitle { display: none; }
    header { height: 120px; }
</style>
</head>
<body>
    <header>
        <div id="hdrImg" style="background-image: url('../images/logo-<%= nvl(session.getAttribute("imageName"), "act") %>.png');"></div>
        <div id="hdrTitle">Special Inventory Tax System</div>    
        <div class="hdrDiv">
            <div id="user-summary" > 
                <div id="system-date">&nbsp;</div>
                <div id="system-time">&nbsp;</div>
                <div id="connected-system-name">&nbsp;</div>
            </div>
        </div>  
        <div class="hdrDiv">
            <%
                Connection connection2 = null;
                PreparedStatement ps2 = null;
                ResultSet rs2 = null;
                try { 
                         
                    connection2 = connect();   
                    ps2 = connection2.prepareStatement("select help_url from acthelp where module='SIT' AND upper(screen)=upper(?)");
                    ps2.setString(1, "portallogin");
                    rs2 = ps2.executeQuery();

                    if(rs2.next()){ 
                        out.print("<div id=\"help\"><i class=\"fa fa-question\"></i><a href=\""+  rs2.getString(1) + "\" target=\"_blank\">Help</a></div>");
                    } 
                } catch (Exception e) {
                     SITLog.error(e, "\r\nProblem getting help for " + current_page + "\r\n");
                } finally {
                    try { rs2.close(); } catch (Exception e) { }
                    rs2 = null;
                    try { ps2.close(); } catch (Exception e) { }
                    ps2 = null;
                    try { connection2.close(); } catch (Exception e) { }
                    connection2 = null;                    
                }// try get help file  
            %>
        </div>
    </header>

<div id="loginDiv">
    <div id="main" style="margin-top: 80px;">

        <div id="login" class="form-group">
            <form action="login.jsp" method="post">
                <div class="form-group">
                  <label for="account">Account:</label>
                  <% if (forwarded){ %>
                        <%= "<br>&nbsp;&nbsp;<span style='font-size: 16px;'>" + request.getParameter("client_name") + "</span>"%>
                        <input type="hidden" name="ddLogin" value="<%= request.getParameter("client_id") %>">
                  <% } else { %>
                      <select name="ddLogin" id="ddLogin" class="form-control" >
                        <%= clients.toString() %>
                      </select>
                  <% }  %>
                </div>
                <div class="form-group">
                  <label for="user">User:</label>
                  <input type="text" name="user" id="user" class="form-control" />
                </div>
                <div class="form-group">
                  <label for="pw">Password:</label>
                  <input type="password" name="pw" ID="pw" class="form-control" />
                </div>
                <div class="toggleText"><a id="pwToggle" style="cursor: pointer;">[show password]</a></div><br>
                <div class="toggleText"><a id="forgotToggle" style="cursor: pointer;">[forgot my password]</a></div>
                <button type="submit" class="btn btn-default pull-right">Submit</button>
            </form><br><br><br>
            <center>If you are a new user or forgot your username,<br>please contact your Tax Office.</center>
        </div><!-- login -->

        <div id="forgot" class="form-group">
            <form action="login.jsp" method="post">
                <div class="form-group">
                  <label for="account">Account:</label>
                  <% if (forwarded){ %>
                        <%= "<br>&nbsp;&nbsp;<span style='font-size: 16px;'>" + request.getParameter("client_name") + "</span>"%>
                        <input type="hidden" name="ddForgot" id="ddForgot" value="<%= request.getParameter("client_id") %>">
                  <% } else { %>
                      <select name="ddForgot" id="ddForgot" class="form-control" >
                        <%= clients.toString() %>
                      </select>
                  <% }  %>
                </div>
                <div class="form-group">
                  <label for="email">Email Address:</label>
                  <input type="text" name="email" id="email" class="form-control" />
                </div>
                <div class="toggleText"><a id="forgotCancel" style="cursor: pointer;">[cancel]</a></div>
                <button type="submit" id="forgotSubmit" class="btn btn-default pull-right">Submit</button>
            </form>            <br><br><br>
            <center>To reset your password, enter your account information and the email address associated with your account.
                <br><br>Once your email address is verified,<br>you will be notified by email.
                <br><br>If you do not have access to your email account or it is not associated with your account,
                please contact the Tax Office for assistance.</center>
        </div><!-- forgot pw -->          

        <div id="instructions">
            <div id="instrTitle">Enter your account information and password</div>

            <% 
            if (isDefined(request.getParameter("message"))) {
                if ("updated".equals(request.getParameter("message"))){ // updated password
                    out.print("<br><br><span style=\"color: red;\">Now log in with your new password.</span>"); 
                } else { // general "bounce back" from accessing pages without being logged in
                    out.print("<br><br><span style=\"color: red;\">Please log in to continue.</span>"); 
                }
            }
            %>
            <span id="errors" style="font-size: 14px; color: red;"><%= errorMessage.toString() %></span>
        </div><!-- instructions -->
       
    </div><!-- /main -->
</div>

    <div id="helpDiv"></div>
    <footer id="footer">&copy;Appraisal &amp; Collection Technologies, LLC.</footer>

    <!-- jQuery and Bootstrap --> 
    <script src="../assets/js/jquery.min.js"></script> 
    <script src="../assets/js/bootstrap.min.js"></script>
    <script src="../assets/js/jquery-ui.min.js"></script> 
    <script src="../assets/js/various.js?<%= (new java.util.Date()).getTime() %>"></script>
<!-- include scripts here -->
    <script>
        $(document).ready(function() {

            var $pw = $("#pw");                                 // L pw input field (used with pwToggle)
            var $forgot = $("#forgot");                         // F container div (F = forgot)
            var $login = $("#login");                           // L container div (L = login)
            var $pwToggle = $("#pwToggle");                     // L toggle pw
            var $forgotToggle = $("#forgotToggle");             // L forgot button
            var $forgotCancel = $("#forgotCancel");             // F cancel button
            var $instructions = $("#instructions #instrTitle"); // instructional text
            var $errors = $("#errors");
            $forgot.hide(); // initial setup

            $pwToggle.on('click', function(){
                if( $pw.prop("type") === "text" ){  
                    $pw.prop("type", "password");
                    $pwToggle.text("[show password]");
                } else {
                   $pw.prop("type", "text");
                   $pwToggle.text("[hide password]");
                }
            });//pwToggle
          
            $forgotToggle.on('click', function(){
                $errors.text("");
                $login.hide();
                $forgot.show();
                $instructions.text("Submit your email address to change password");
            });//forgotToggle
            $forgotCancel.on('click', function(){
                $errors.text("");
                $login.show();
                $forgot.hide();
                $instructions.text("Enter your account information and password");
            });//forgotToggle
  
            $(document).find("#forgotSubmit").on('click', function(e){
                e.preventDefault();
                e.stopPropagation();
                var $email = $("#email").prop("value");
                var $client_id = $("#ddForgot").prop("value");
                if (validateEmail($("#email").prop("value"))){
                    $errors.text("");
                    $.ajax({
                        type: "GET",
                        url: '../__resetPW.jsp',
                        data: { email: $email, client_id: $client_id },
                        contentType: "application/json; charset=utf-8",
                        success: successFunc,
                        error: errorFunc
                    });
                } else {
                    $errors.text("Please enter a valid email address");
                }
            });

            function successFunc(data, status) { 
                $login.show();
                $forgot.hide();
                $errors.text("Thank you. Check your email and follow the instructions." ); 
            }
            function errorFunc(data, status) { $errors.text("There was a problem"); }
        
            function validateEmail(sEmail) {
                var filter = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
                if (filter.test(sEmail)) {
                    return true;
                } else {
                    return false;
                }
            }
        });
    </script>
</body>
</html>