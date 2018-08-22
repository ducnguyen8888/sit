<% /*@page import="java.util.Arrays" */
%><%@ include file="_configuration.inc" 
%><%--

NEED an ERROR page....


--%><%
    StringBuilder errorMessage = new StringBuilder();



    String [][]             clients             = null;


    try ( Connection con = act.util.Connect.open(datasource);
          Statement st = con.createStatement();
        )
    {
        try ( ResultSet rs = st.executeQuery("select distinct client.client_id, client.client_name "
                                            + " from sit_users join client on (client.client_id=sit_users.client_id) "
                                            + " order by client.client_name"
                                            );
            )
        {
            ArrayList<String[]> clientNames = new ArrayList<String[]>();
            while ( rs.next() )
            {
                clientNames.add(new String[] { rs.getString("client_id"), rs.getString("client_name") });
            }
            clients = clientNames.toArray(new String[0][2]);
        }

        try ( ResultSet rs = st.executeQuery("select lower(substr(screen,7)||'.jsp') as \"page\", help_url "
                                            + " from acthelp where module='SIT' and lower(screen) like 'portal%'"
                                            );
            )
        {
            onlineHelp.clear();
            while ( rs.next() )
            {
                onlineHelp.put(rs.getString("page"), rs.getString("help_url"));
            }
        }
    }
    catch (Exception exception)
    {
        // Need to direct to error page....
        out.println("<li> Exception: " + exception.toString());
        if ( true ) return;
    }
%><!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Tax system for Special Inventory items">
    <meta name="author" content="Appraisal and Collection Technologies, LLC">
    <title>User Sign In</title>

    <link href="assets/css/bootstrap.css" rel="stylesheet">
    <link href="assets/css/font-awesome.min.css" rel="stylesheet">
    <link href="assets/css/jquery-ui.min.css" rel="stylesheet">
    <link href="assets/css/styles.css?<%= (new java.util.Date()).getTime() %>" rel="stylesheet">

    <style>
        header { height: 120px; }

        .message-group { }
        .errors { position: relative; height: auto; min-height: 45px; margin-top: 15px; font-size: 14px; color: red; }


        #reset select:disabled { background-color: #f5f5f5; border: none; outline: none; }
        #reset select:disabled:focus { border: none; outline: none; }
        #reset input:read-only { background-color: #f5f5f5; border: none; outline: none; }
        #reset input:read-only:focus { border: none; outline: none; }


        .pinReveal, .gotoLogin { cursor: pointer; float: left; font-size: 12px; }
        #newPinLogin { display: none; }
        #newPinLogin div { margin: 25px 120px; }
        #newPinLogin button { padding: 0px 25px; color: red; cursor: pointer }
        #forgotEmailNotice { display: none; }
        #forgotEmailSubmitted { display: none; }


        #pinRequirements { display: block; margin-top: 10px; }

        #pinRequirements li { padding-top:10px; padding-bottom: 5px; margin-left: 15px; color: red; padding-left: 35px; list-style: none; }
        #pinRequirements li span { display: none; }
        #pinRequirements li.meets { color: green; xfont-weight: bold; padding-left: 20px; }
        #pinRequirements li.meets span { display: inline-block; width: 10px; }

        #defaultPinRequirements { display: block; }
        #harrisPinRequirements { display: none; }
        #pinRequirements .pinOk { display:none; margin-top:15px;color: darkgreen; font-weight: bold; }



        #content { position: fixed; overflow:auto; top:121px; left: 0px; right: 0px; bottom: 15px; xbackground-color: lightgreen; padding: 30px 60px; }
        .displayGroup { position: relative; width: 1000px; min-width: 1000px; xheight: 500px; xbackground-color: lightyellow; margin: 40px; clear: both; }
        .displayGroup > div:first-child { float: left; background: #f5f5f5; border: 1px solid #d3d3d3;
                                            padding: 20px 30px; width: 400px; height: 380px; 
                                            -webkit-border-radius: 10px; -moz-border-radius: 10px; border-radius: 10px;
                                            }
        .displayGroup > div:last-child { float: left; xbackground: #f5f5f5; border-left: 1px solid #d3d3d3;
                                            padding: 20px 30px; width: 450px; height: 300px; margin-top: 20px; 
                                            margin-left: 30px; font-size: 1.2em; color: #005eb9;
                                            }
        .displayGroup.fullSize > div:first-child { float: left; background: #f5f5f5; border: 1px solid #d3d3d3;
                                            padding: 20px 30px; width: 800px; height: 380px; 
                                            -webkit-border-radius: 10px; -moz-border-radius: 10px; border-radius: 10px;
                                            }
        .displayGroup.fullSize title { font-weight: bold;
                                            }
        .displayGroup.fullSize div { margin-bottom: 30px;
                                            }

        #forgot.displayGroup > div:first-child { height: 480px; }
        #reset.displayGroup  > div:first-child { height: 440px; }


        @keyframes spinner {
            from { transform: rotate(0deg);   }
            to   { transform: rotate(360deg); }
        }

        .spinner:before {
            content: '';
            box-sizing: border-box;
            position: absolute;
            xtop: 50%;
            xleft: 50%;
            top: 10px;
            left: 50px;
            width: 20px;
            height: 20px;
            margin-top: -10px;
            margin-left: -76px;
            border-radius: 50%;
            border: 2px solid #ccc;
            border-top-color: #333;
            xborder-bottom-color: #333;
            animation: spinner 0.6s linear infinite;
        }
    </style>

</head>
<body>
    <header>
        <div id="hdrImg" style="background-image: url('images/logo-<%= nvl(session.getAttribute("imageName"), "act") %>.png');"></div>
        <div id="hdrTitle">Special Inventory Tax System</div>    
        <div class="hdrDiv">
            <div id="user-summary" > 
                <div id="system-date">&nbsp;</div>
                <div id="system-time">&nbsp;</div>
                <div id="connected-system-name">&nbsp;</div>
            </div>
        </div>  
        <div class="hdrDiv" style="min-height: 22px;"> 
            <div id="help"><i class="fa fa-question"></i><a href="<%= onlineHelpURL %>" target="_blank">Help</a></div>
        </div>
    </header>

    <div id="content"> 
        <div id="login" class="displayGroup">
            <div class="form-group">
                <form id="loginForm" action="login.jsp" method="post">
                    <div class="form-group">
                        <label for="loginClient">Account:</label>
                        <select id="loginClient" name="client" class="client form-control" >
                            <!--<option value=""></option>-->
                            <optgroup label="Select Account">
                                <%
                                for ( String[] client : clients ) {
                                    %><option value="<%= client[0] %>" <%= (client[0].equals(request.getParameter("client_id")) ? "selected" : "") %>>
                                        <%= client[1] %>
                                      </option>
                                    <%
                                }
                                %>
                            </optgroup>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="user">User:</label>
                        <input type="text" name="user" id="user" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label for="pin">Password:</label>
                        <input type="password" name="pin" ID="pin" class="form-control" />
                    </div>
                    <div style="width: 40%;display:inline-block;">
                        <div class="toggleText"><a class="pinReveal" style="cursor: pointer;">[show password]</a></div><br>
                        <div class="toggleText"><a id="forgotToggle" style="cursor: pointer;">[forgot my password]</a></div>
                    </div>
                    <div style="display:inline-block;float:right;">
                        <button type="submit" class="btn btn-default pull-right">Submit</button>
                    </div>
                </form><br><br><br>
                <center>If you are a new user or forgot your username,<br>please contact your Tax Office.</center>
            </div><!-- login -->

            <div id=loginMessages class="message-group">
                <div class=title>Enter your account information and password</div>
                <div class=errors><%= errorMessage.toString() %></div>
            </div>
        </div>

        <div id="forgot" class="displayGroup">
            <div class="form-group">
                <form id="forgotPinForm" action="login.jsp" method="post">
                    <div class="form-group">
                        <label for="forgotClient">Account:</label>
                        <select id="forgotClient" name="client" class="client form-control" >
                            <optgroup label="Select Account">
                                <%
                                for ( String[] client : clients ) {
                                    %><option value="<%= client[0] %>" <%= (client[0].equals(request.getParameter("client_id")) ? "selected" : "") %>>
                                        <%= client[1] %>
                                      </option>
                                    <%
                                }
                                %>
                            </optgroup>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="forgotUser">User:</label>
                        <input type="text" name="user" id="forgotUser" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label for="forgotEmail">Email Address:</label>
                        <input type="text" name="email" id="forgotEmail" class="form-control" />
                    </div>
                    <div class="toggleText"><a class="gotoLogin" style="cursor: pointer;">[cancel]</a></div>
                    <button type="submit" id="forgotSubmit" class="btn btn-default pull-right">Submit</button>
                </form>
                <br><br>
                <div style="text-align:center;padding-top: 20px;">
                    To reset your password enter your account information and the email address associated with your account.
                    <br><br>
                    Once your email address is verified you will be notified by email with the next steps to take.
                    <br><br>
                    If you do not have access to your email account, or it is not associated with your account,
                    please contact the Tax Office for assistance.
                </div>
            </div>

            <div id=forgotMessages class="message-group">
                <div class=title>Submit your email address to change password</div>
                <div class=errors><%= errorMessage.toString() %></div>
                <div id="forgotEmailNotice">
                    An email has been sent to your email address with additional instructions<br><br>
                    <div style="color:red;">
                    You must follow the steps outlined in the email to complete resetting your password
                    </div>
                </div>
            </div>
        </div>

        <div id="reset" class="displayGroup">
            <div class="form-group">
                <form id="resetPinForm" action="login.jsp" method="post">
                    <input type="hidden" name="resetId" id="resetId" value="<%= nvl(request.getParameter("accessid")) %>">
                    <input type="hidden" name="client"  id="resetClientId" value="">
                    <input type="hidden" name="pin"     id="resetClientPin" value="">

                    <div class="form-group">
                        <label for="resetClient">Account:</label>
                        <select id="resetClient" name="client" class="client form-control">
                            <optgroup label="Select Account">
                                <%
                                for ( String[] client : clients ) {
                                    %><option value="<%= client[0] %>" <%= (client[0].equals(request.getParameter("client_id")) ? "selected" : "") %>>
                                        <%= client[1] %>
                                      </option>
                                    <%
                                }
                                %>
                            </optgroup>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="resetUser">User:</label>
                        <input type="text" name="user" id="resetUser" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label for="newPin">New Password:</label>
                        <input type="password" name="newpin" id="newPin" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label for="confirmPin">Confirm New Password:</label>
                        <input type="password" name="cpin" id="confirmPin" class="form-control" />
                    </div>

                    <div class="toggleText"><a class="pinReveal" style="cursor: pointer;">[show password]</a></div><br>
                    <button type="submit" id="resetSubmit" class="btn btn-default pull-right">Submit</button>
                </form><br><br><br>
                <center>If you forgot your username or are having problems please contact your Tax Office.</center>
            </div>

            <div id=resetMessages class="message-group">
                <div class=title>Create and verify your new password</div>
                <div class=errors><%= errorMessage.toString() %></div>
                <% 
                if (isDefined(request.getParameter("message"))) {
                    if ("updated".equals(request.getParameter("message"))){ // updated password
                        out.print("<br><br><span style=\"color: red;\">Now log in with your new password.</span>"); 
                    } else { // general "bounce back" from accessing pages without being logged in
                        out.print("<br><br><span style=\"color: red;\">Please log in to continue.</span>"); 
                    }
                }
                %>

                <div id="newPinLogin">
                    You password has been updated <br><br>
                    Please login with your new password to continue:
                    <div><button class="gotoLogin">Login</button></div>
                </div>
                <div id="pinRequirements">
                    <div id="defaultPinRequirements">
                        Your Password must be:
                        <li class="pinLength">  <span>&#10004;</span> 8 to 15 characters in length </li>
                        <br>and meet at least three of these requirements:
                        <li class="pinUpper">   <span>&#10004;</span> At least one upper case character </li>
                        <li class="pinLower meets">   <span>&#10004;</span> At least one lower case character </li>
                        <li class="pinNumber">  <span>&#10004;</span> At least one number character </li>
                        <li class="pinSpecial"> <span>&#10004;</span> At least one special character </li>

                        <div class="pinOk">&#10004; Your password meets the requirements</div>
                    </div>
                    <div id="harrisPinRequirements">
                        Your Password must be:
                        <li class="pinLength">  <span>&#10004;</span> 8 to 15 characters in length </li>
                        <br>and meet at least three of these requirements:
                        <li class="pinUpper">   <span>&#10004;</span> At least one upper case character </li>
                        <li class="pinLower">   <span>&#10004;</span> At least one lower case character </li>
                        <li class="pinNumber">  <span>&#10004;</span> At least one number character </li>
                        <li class="pinSpecial"> <span>&#10004;</span> At least one special character </li>

                        <div class="pinOk">&#10004; Your password meets the requirements</div>
                    </div>
                </div>
            </div>
        </div>


        <div id="forgotEmailSubmitted" class="displayGroup fullSize">
            <div class="message-group">
                <div>
                    Your password reset request has been submitted.
                </div>
                <div>
                    If the email address you provided matches the one associated with your account you should receive a response email shortly.
                </div>
                <div>
                    Please follow the instructions in the email to complete your password reset.
                </div>
            </div>
        </div>
    </div><!-- content -->

    <footer id="footer">&copy;Appraisal &amp; Collection Technologies, LLC.</footer>

    <!-- jQuery and Bootstrap --> 
    <script src="assets/js/jquery.min.js"></script> 
    <script src="assets/js/bootstrap.min.js"></script>
    <script src="assets/js/jquery-ui.min.js"></script> 
    <script src="assets/js/various.js?<%= (new java.util.Date()).getTime() %>"></script>

    <script>
        $(function()
        {
            if ( ! $("#help a").attr("href") ) $("#help").hide();

            // The login view should be shown by default
            $("#login").show();
            $("#forgot,#reset").hide();
            $("#newPinLogin,#forgotEmailNotice").hide();

            $(".pinReset").click(showPinReset);

            // If a reset id was specified this should be the final step
            // of the reset request.
            if ( $("#resetId") && $("#resetId").val().length > 4 )
            {
                $("#reset,#pinRequirements").show();
                $("#login,#forgot").hide();
            }

            // Change the application client seal based on the user's selected client
            $("#loginClient").change(function()
            {
                $("#defaultPinRequirements").show();
                $("#harrisPinRequirements").hide();

                var image = $("#hdrImg");
                switch ( $(this).val() )
                {
                    case  "7580"        :   image.css("background-image", "url('images/logo-dallas.png')");
                                            break;
                    case  "79000000"    :   image.css("background-image", "url('images/logo-fbc.png')");
                                            break;
                    case  "98000000"    :   image.css("background-image", "url('images/logo-galveston.png')");
                                            break;
                    case  "94000000"    :
                    case  "94500000"    :   image.css("background-image", "url('images/logo-elpaso.png')");
                                            break;
                    case  "2000"        :   image.css("background-image", "url('images/logo-harris.png')");
                                            $("#defaultPinRequirements,#harrisPinRequirements").toggle();
                                            break;
                    default             :   image.css("background-image", "url('images/logo-act.png')");
                                            break;
                }

                // Keep all client drop-down names consistent
                $("#forgotClient,#resetClient,#resetClientId").val($(this).val());

                // Force PIN re-validation, if client has changed PIN requirements may have also
                $("#newPin").keyup();
            }).change();

            // #loginClient is the "master" client all actions based on 
            // which client is selected should be based on that change action
            $("#forgotClient,#resetClient").change(
                function()
                {
                    $("#loginClient").val($(this).val()).change();
                }
            );
            $("#loginClient").val("").change();

            // Reveal/Conceal PIN
            $(".pinReveal").click(
                function()
                {
                    var pinField = $("#pin,#newPin,#confirmPin");
                    if ( pinField.attr("type") == "text" )
                    {   pinField.attr("type","password");
                        $(".pinReveal").html("[show password]");
                    }
                    else
                    {   pinField.attr("type","text");
                        $(".pinReveal").html("[hide password]");
                    }
                }
            );


            // Switch between login form and forgot pin form
            $("#forgotToggle,#forgotCancel").click(
                function()
                {
                    $("#loginMessages .errors,#forgotMessages .errors").html("");
                    $("#login,#forgot").toggle();
                    $("#login input,#forgot input").val("");
                    $("#forgotEmailNotice").hide();
                    $("#forgotSubmit").show();
                }
            );

            // Show login form
            $(".gotoLogin").click(
                function()
                {
                    $("#errors").html("");
                    $("#login").show();
                    $("#forgot,#reset").hide();
                }
            );



            // Verify the PIN security when the value changes
            $("#newPin").keyup(
                function()
                {
                    $(".pinLength,.pinUpper,.pinLower,.pinNumber,.pinSpecial").removeClass("meets");
                    $(".pinOk").hide();
                    $("#resetSubmit").attr("disabled","disabled");

                    var isValidPin = false;
                    switch ( $("#resetClient").val() )
                    {
                        case    "2000"      :   isValidPin = harrisPinValidation();
                                                break;
                        default             :   isValidPin = defaultPinValidation();
                                                break;
                    }

                    if ( isValidPin )
                    {
                        $(".pinOk").show();
                        $("#resetSubmit").removeAttr("disabled");
                    }
                }
            ).keyup();





            // Verify the form fields on login and control submission to server
            $("#loginForm").submit(
                function(event)
                {
                    event.preventDefault();
                    event.stopPropagation();

                    $("#loginMessages .errors").html("");
                    var hasErrors = false;
                    if ( ! $("#loginClient").val() || $("#loginClient").val().length == 0 ) 
                    {
                        $("#loginMessages .errors").html($("#loginMessages .errors").html()+"Please specify a client<br>");
                        hasErrors = true;
                    }
                    if ( $("#user").val().length == 0 ) 
                    {
                        $("#loginMessages .errors").html($("#loginMessages .errors").html()+"Please specify a username<br>");
                        hasErrors = true;
                    }
                    if ( $("#pin").val().length == 0 ) 
                    {
                        $("#loginMessages .errors").html($("#loginMessages .errors").html()+"Please specify a password <br>");
                        hasErrors = true;
                    }

                    if ( ! hasErrors ) {
                        $("#loginMessages .errors").html("<div class=spinner>Processing...</div>");
                        $("#loginSubmit").hide();
                        var v = $.post( "login_ws.jsp", $("#loginForm").serialize() )
                                .done(
                                    function (data, status, jqxhr)
                                    {
                                        $("#loginMessages .errors").html("");

                                        // status: "success"
                                        // jqhdr:  {"readyState":4,"responseText":"","status":200,"statusText":"OK"}
                                        // \"status\": \"ok\", \"action\": \"failed\"
                                        console.log("Done response");
                                        console.log(data);
                                        try
                                        {
                                            var response = JSON.parse(data);
                                            if ( response.status != "ok" )
                                            {
                                                $("#loginMessages .errors").html("Processing Error");
                                                $("#loginMessages .errors").html($("#loginMessages .errors").html() + "<br><br>" + response.detail);
                                            } 
                                            else if ( response.action == "locked" )
                                            {
                                                $("#resetMessages .errors").html("This account is locked<br><br>Contact the Tax Office for assistance");
                                            } 
                                            else if ( response.action == "pinchange" )
                                            {
                                                $("#resetMessages .errors").html("You must reset your password");
                                                $("#resetClientPin").val($("#pin").val());
                                                console.log("Client: " + $("#resetClientId").val());
                                                console.log("User:   " + $("#resetClientUser").val());
                                                console.log("PIN:    " + $("#resetClientPin").val());
                                                console.log("Client: " + $("#resetClient").val());
                                                showPinReset();
                                            } 
                                            else if ( response.action != "ok" )
                                            {
                                                $("#loginMessages .errors").html("Failed to verify account<br><br>Please verify your username and email");
                                                $("#loginMessages .errors").html($("#loginMessages .errors").html()+"<br><br>"+response.action);
                                            } 
                                            else 
                                            {
                                                $("#loginMessages .errors").html("");
                                                location = "dealerships.jsp";
                                            }
                                        }
                                        catch (err)
                                        {
                                            $("#loginMessages .errors").html("Failed to complete your request:<br><br>"+err);
                                        }
                                    }
                                )
                                .fail(
                                    function (data, status, jqxhr)
                                    {
                                        $("#loginMessages .errors").html("Failed to verify account, processing error: ");
                                        $("#loginMessages .errors").html($("#loginMessages .errors").html()+jqxhr.status);
                                    }
                                )
                                .always(
                                    function (data, status, jqxhr)
                                    {
                                        $("#loginSubmit").show();
                                    }
                                );
                    }
                }
            );



            // Verify the form fields on reset submit and control submission to server
            $("#forgotPinForm").submit(
                function(event)
                {
                    event.preventDefault();
                    event.stopPropagation();

                    $(".errors").html("");
                    var hasErrors = false;

                    if ( ! $("#forgotClient").val() || $("#forgotClient").val().length == 0 ) 
                    {
                        $("#forgotMessages .errors").html($("#forgotMessages .errors").html()+"Please specify a client<br>");
                        hasErrors = true;
                    }
                    if ( $("#forgotUser").val().length == 0 ) 
                    {
                        $("#forgotMessages .errors").html($("#forgotMessages .errors").html()+"Please specify a username<br>");
                        hasErrors = true;
                    }
                    if ( $("#forgotEmail").val().length == 0 ) 
                    {
                        $("#forgotMessages .errors").html($("#forgotMessages .errors").html()+"Please specify an email address <br>");
                        hasErrors = true;
                    }
                    else
                    {
                        var filter = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
                        if ( ! filter.test($("#forgotEmail").val()) ) 
                        {
                            $("#forgotMessages .errors").html($("#forgotMessages .errors").html()+"Please specify a valid email address <br>");
                            hasErrors = true;
                        }
                    }

                    if ( ! hasErrors ) {
                        $("#forgotMessages .errors").html("<div class=spinner>Processing...</div>");
                        $("#forgotSubmit").hide();
                        $("#forgotEmailNotice").hide();
                        var v = $.post( "login_ws.jsp", $("#forgotPinForm").serialize() )
                                .done(
                                    function (data, status, jqxhr)
                                    {
                                        $("#forgotMessages .errors").html("");

                                        // status: "success"
                                        // jqhdr:  {"readyState":4,"responseText":"","status":200,"statusText":"OK"}
                                        // \"status\": \"ok\", \"action\": \"failed\"
                                        console.log(data);
                                        try
                                        {
                                            var response = JSON.parse(data);
                                            if ( response.status != "ok" )
                                            {
                                                $("#forgotMessages .errors").html("Processing Error");
                                                $("#forgotMessages .errors").html($("#forgotMessages .errors").html() + "<br><br>" + response.detail);
                                            } 
                                            else if ( $("#forgotClient").val() == 2000 )
                                            {
                                                $("#forgot").hide();
                                                $("#forgotEmailSubmitted").show();
                                            } 
                                            else
                                            {
                                                if ( response.action != "ok" )
                                                {
                                                    $("#forgotMessages .errors").html("Failed to verify account<br><br>Please verify your username and email");
                                                    $("#forgotMessages .errors").html($("#forgotMessages .errors").html()+"<br><br>"+response.action);
                                                } 
                                                else 
                                                {
                                                    $("#forgotMessages .errors").html("");
                                                    $("#forgotEmailNotice").show();
                                                }
                                            }
                                        }
                                        catch (err)
                                        {
                                            $("#forgotMessages .errors").html("Failed to complete your request:<br><br>"+err);
                                        }
                                    }
                                )
                                .fail(
                                    function (data, status, jqxhr)
                                    {
                                        $("#forgotMessages .errors").html("Failed to verify account, processing error: ");
                                        $("#forgotMessages .errors").html($("#forgotMessages .errors").html()+jqxhr.status);
                                    }
                                )
                                .always(
                                    function (data, status, jqxhr)
                                    {
                                        $("#forgotSubmit").show();
                                    }
                                );


                        // On success
                        //$("#forgotEmailNotice").toggle();
                        //$("#forgotSubmit").hide();
                    }
                }
            );


            // Verify the form fields on reset submit and control submission to server
            $("#resetPinForm").submit(
                function(event)
                {
                    event.preventDefault();
                    event.stopPropagation();

                    $(".errors").html("");
                    var hasErrors = false;

                    if ( ! $("#resetClient").val() || $("#resetClient").val().length == 0 ) 
                    {
                        $("#resetMessages .errors").html($("#resetMessages .errors").html()+"Please specify a client<br>");
                        hasErrors = true;
                    }
                    if ( $("#resetUser").val().length == 0 ) 
                    {
                        $("#resetMessages .errors").html($("#resetMessages .errors").html()+"Please specify a username<br>");
                        hasErrors = true;
                    }
                    if ( $("#newPin").val() != $("#confirmPin").val() ) 
                    {
                        $("#resetMessages .errors").html($("#resetMessages .errors").html()+"Passwords do not match<br>");
                        hasErrors = true;
                    }

                    if ( ! hasErrors ) {
                        console.log("Submitting...");

                        // On success, hide pin requirements and show re-login success message
                        // $("#newPinLogin,#pinRequirements").toggle();

                        $("#resetMessages .errors").html("<div class=spinner>Processing...</div>");
                        $("#resetSubmit").hide();
                        $("#newPinLogin").hide();

                        var v = $.post( "login_ws.jsp", $("#resetPinForm").serialize() )
                                .done(
                                    function (data, status, jqxhr)
                                    {
                                        $("#resetMessages .errors").html("");

                                        // status: "success"
                                        // jqhdr:  {"readyState":4,"responseText":"","status":200,"statusText":"OK"}
                                        // \"status\": \"ok\", \"action\": \"failed\"
                                        console.log(data);
                                        try
                                        {
                                            var response = JSON.parse(data);
                                            if ( response.status != "ok" )
                                            {
                                                $("#resetMessages .errors").html("Processing Error");
                                                $("#resetMessages .errors").html($("#resetMessages .errors").html() + "<br><br>" + response.detail);
                                            } 
                                            else if ( response.action != "ok" )
                                            {
                                                $("#resetMessages .errors").html("Failed to verify account<br><br>Please verify your username and email");
                                                $("#resetMessages .errors").html($("#resetMessages .errors").html()+"<br><br>"+response.action);
                                            } 
                                            else 
                                            {
                                                $("#resetMessages .errors").html("");
                                                $("#newPinLogin").show();
                                                $("#pinRequirements").hide();
                                            }
                                        }
                                        catch (err)
                                        {
                                            $("#resetMessages .errors").html("Failed to complete your request:<br><br>"+err);
                                        }
                                    }
                                )
                                .fail(
                                    function (data, status, jqxhr)
                                    {
                                        $("#resetMessages .errors").html("Failed to verify account, processing error: ");
                                        $("#resetMessages .errors").html($("#resetMessages .errors").html()+jqxhr.status);
                                    }
                                )
                                .always(
                                    function (data, status, jqxhr)
                                    {
                                        $("#resetSubmit").show();
                                    }
                                );


                    }
                }
            );
        });


        function showPinReset()
        {
            var user = $("#user").val();
            if ( user.length > 0 )
            {
                $("#resetClientId").val($("#resetClient").val());
                $("#resetUser").val(user);
                $("#resetPin").val($("#pin").val());
                $("#resetClient").prop("disabled",true);
                $("#resetUser").prop("readonly",true);
            }
            else
            {
                $("#resetUser").val("");
                $("#resetPin").val("");
                $("#resetClient").removeProp("disabled");
                $("#resetUser").removeProp("readonly");
            }
            $("#newPin,#confirmPin,#pin").val("");
            $("#newPinLogin").hide();
            $("#pinRequirements").show();
            $("#login,#forgot").hide();
            $("#reset").show();
        }



        // Controls the default PIN security validation for new PINs
        function defaultPinValidation()
        {
            var value = $("#newPin").val();
            if ( value.replace(/[^A-Z]/g,"").length > 0 )
            {
                $(".pinUpper").addClass("meets");
            }

            if ( value.replace(/[^a-z]/g,"").length > 0 )
            {
                $(".pinLower").addClass("meets");
            }

            if ( value.replace(/[^0-9]/g,"").length > 0 )
            {
                $(".pinNumber").addClass("meets");
            }

            if ( value.replace(/[a-zA-Z0-9 ]/g,"").length > 0 )
            {
                $(".pinSpecial").addClass("meets");
            }

            if ( value.length >= 8 && value.length <= 15 )
            {
                $(".pinLength").addClass("meets");
            }

            return $("#defaultPinRequirements .meets").length >= 4 && $(".pinLength").hasClass("meets");
        }

        // PIN security validation for Harris County. Currently this is the
        // same as the default validation. It is included for use as a template
        // to add alternate client validations if they differ from the default.
        function harrisPinValidation()
        {
            var value = $("#newPin").val();
            if ( value.replace(/[^A-Z]/g,"").length > 0 )
            {
                $(".pinUpper").addClass("meets");
            }

            if ( value.replace(/[^a-z]/g,"").length > 0 )
            {
                $(".pinLower").addClass("meets");
            }

            if ( value.replace(/[^0-9]/g,"").length > 0 )
            {
                $(".pinNumber").addClass("meets");
            }

            if ( value.replace(/[a-zA-Z0-9 ]/g,"").length > 0 )
            {
                $(".pinSpecial").addClass("meets");
            }

            if ( value.length >= 8 && value.length <= 15 )
            {
                $(".pinLength").addClass("meets");
            }

            return $("#harrisPinRequirements .meets").length >= 4 && $(".pinLength").hasClass("meets");
        }

        $(document).ready(function() {
        return;
        
            var $pw = $("#pw");                                 // L pw input field (used with pwToggle)
            var $forgot = $("#forgot");                         // F container div (F = forgot)
            var $login = $("#login");                           // L container div (L = login)
            var $pwToggle = $("#pwToggle");                     // L toggle pw
            var $forgotToggle = $("#forgotToggle");             // L forgot button
            var $forgotCancel = $("#forgotCancel");             // F cancel button
            var $instructions = $("#instructions #instrTitle"); // instructional text
            var $errors = $("#errors");
            $forgot.hide(); // initial setup

            /******************
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
            ******/

            $(document).find("#forgotSubmit").on('click', function(e){
                e.preventDefault();
                e.stopPropagation();
                var $email = $("#email").val();
                var $client_id = $("#ddForgot").prop("value");
                if (validateEmail($email)){
                    $errors.text("");
                    $.ajax({
                        type: "GET",
                        url: '__resetPW.jsp',
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
                $errors.text("Thank you. Check your email and follow the instructions"); 
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