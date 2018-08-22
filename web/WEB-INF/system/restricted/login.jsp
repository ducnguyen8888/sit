<%@ page import="act.app.security.*" 
         contentType="text/html;charset=windows-1252"
%><%--
javax.servlet.forward.context_path	/minimal
javax.servlet.forward.servlet_path	/_system/restricted/login.jsp
javax.servlet.forward.request_uri	/minimal/_system/restricted/success.jsp
javax.servlet.forward.path_info	    null
javax.servlet.forward.query_string	abc=123
--%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");

    String failureReason = nvl((String)request.getAttribute("user-login-failure"));
    if ( "User credentials were not defined".equals(failureReason) ) failureReason = "";

    User user = (ApplicationUser) session.getAttribute("WebAdminUser");
    if ( user != null && user.isValid() ) {
        String accessUrlPrefix = nvl((String)request.getAttribute("accessUrlPrefix"));
        response.sendRedirect(request.getRequestURL().toString().replaceAll("(.*)/login.jsp","$1/default.jsp").replace(accessUrlPrefix,""));
        return;
    }

    String requestedURI = null;
    String postURI = request.getRequestURI();
    if ( request.getAttribute("javax.servlet.forward.request_uri") != null ) {
        requestedURI = postURI = (String) request.getAttribute("javax.servlet.forward.request_uri");
        if ( request.getAttribute("javax.servlet.forward.query_string") != null ) {
            postURI += "?" + (String) request.getAttribute("javax.servlet.forward.query_string");
        }
    }



%><%!
boolean isDefined(String val) { return val != null && val.length() > 0; }
String  nvl(String val) { return (val == null ? "" : val); }

%><!DOCTYPE html>
<html lang="en-us">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252"/>
        <title>Security Access</title>
        <style>
            html { 
                    background: url("<%= request.getContextPath() %>/resources/images/stock-photo-198802483.jpg") no-repeat center center fixed; 
            
                    -webkit-background-size: cover;
                    -moz-background-size: cover;
                    -o-background-size: cover;
                    background-size: cover;
                    font-family: 'Arial Narrow', Arial, sans-serif; font-size: 16px;
                }
            .login-form {
                background:rgba(19, 35, 47, .9);
                max-width:400px; margin: 40px auto; padding: 40px;
                border-radius:4px;
                box-shadow: 0 4px 10px 4px rgba(19, 35, 47, .3); color: white;
                padding: 35px; text-overflow: ellipse;
            }

            .login-form h1 {
                margin:0 0 40px;
                text-align:center; color: #ffffff;
                font-weight: light;
            }

            .instruction-form {
                background:rgba(19, 35, 47, .9);
                max-width:750px; margin: 40px auto; padding: 40px;
                border-radius:4px;
                box-shadow: 0 4px 10px 4px rgba(19, 35, 47, .3); color: white;
                padding: 35px; text-overflow: ellipse;
            }

            .instruction-form h1 {
                margin:0 0 40px;
                text-align:center; color: #ffffff;
                font-weight: light;
            }

            label {
                position: absolute;
                left:13px;
                transform:translateY(12px) translateX(5px);
                color: rgba(160, 179, 176, .5);
                transition: all 0.25s ease;
                -webkit-backface-visibility: hidden;
                pointer-events: none;
                font-size:22px;
            }
            label .req {
                margin:2px;
            }

            label.active {
                transform:translateY(53px);
                left:2px; font-size:14px;
            }

            label.highlight {
                color: #f0f0f0; 
            }

            input, textarea {
                font-size:22px; color: #ffffff; 
                display:block; width:95%; height:100%;
                padding:10px 15px;
                background:none; background-image:none;
                border:1px solid lightgrey; border-radius:2px;
                transition: border-color .25s ease, box-shadow .25s ease;
                &:focus {
                    outline:0;
                    border-color: #1ab188; color:blue;
                }
            }
            .field-wrap {
                position:relative;
                margin-bottom:40px;
            }

            .button {
                border:0;
                outline:none;
                border-radius:0;
                padding:15px 0;
                font-size:1.5rem; font-weight: bold; color: #ffffff;
                text-transform:uppercase;
                letter-spacing:.1em;
                background: #1ab188;
                transition:all.5s ease;
                -webkit-appearance: none;
                cursor: pointer;
            }
            .button:hover, .button:focus { background:lightblue; }

            .button-block {
                display:block;
                width:100%;
            }

            </style>
    <script src="<%= request.getContextPath() %>/resources/js/jquery-3.2.1.min.js"></script>
    <script>
        $(function() {
            $("input").focus(function() {
                var label = $(this).prev("label");
                    if ( $(this).val() === "" ) {
                        label.removeClass("highlight");
                    } else {
                        label.addClass("highlight");
                    }
            });
            $("input").keyup(function() { 
                var label = $(this).prev("label");
                    if ( $(this).val() === "" ) {
                        label.removeClass("active highlight");
                    } else {
                        label.addClass("active highlight");
                    }
            }).keyup();
        });
        document.addEventListener("keyup", (event) => {
            const keyName = event.key;
            const ctrlKeyPressed = event.ctrlKey;
            if ( ctrlKeyPressed && keyName == "Home" ) {
                var parser = location;
                location = parser.origin + parser.pathname.replace(/(\/[^\/]*\/[^\/]*\/).*/,"$1default.jsp");
                return;

                // Reference fields
                // var parser = location;
                // parser.protocol // => "http:"
                // parser.host     // => "example.com:3000"
                // parser.hostname // => "example.com"
                // parser.port     // => "3000"
                // parser.pathname // => "/pathname/"
                // parser.hash     // => "#hash"
                // parser.search   // => "?search=test"
                // parser.origin   // => "http://example.com:3000"
                //
                // KeyUp/KeyDown Events
                // event.ctrlKey    event.altKey    event.shiftKey
                // true/false: is the specified key pressed

            }
        }, false);

    </script>
</head>
<body>
<div style="position:relative;width:58%;margin:0px; text-align: center; vertical-align: top; padding: auto; display: inline-block;">
    <div class="instruction-form" >
        <h1>Administrative Access</h1>
    </div>
    <div class="instruction-form" >
        <% if ( requestedURI == null ) { %>
        <div style="margin:0px 20px 20px 20px;padding:10px 20px 40px;">Please enter your login information</div>
        <% } else { %>
        <div style="margin:0px 20px 20px 20px;background-color: #1e1e1e;padding:10px 20px 40px;border-radius:4px;">
        <h2 style="xcolor:lightblue;xtext-decoration:underline;"> Authorization Required </h2>
        <span style="xcolor:lightblue;">You must be authorized to access the following:</span>
        <div style="color:lightblue;font-weight: bold;margin:20px 0px;"><%= requestedURI %></div>
        <span style="font-style: italic;xcolor:lightblue;">Please login to access this page</span>
        </div>
        <% } %>
        <% if ( isDefined(failureReason) ) { %>
            <div style="color:red;margin:0px 20px 20px 20px;font-weight: bold;padding:10px 20px 20px;background-color: #eeeeee;border-radius:4px;">
                <%= failureReason %>
            </div>
        <% } %>
    </div>
</div>
<div style="position:relative;width:38%;margin:0px; text-align: center; padding: auto; display: inline-block;min-width: 450px;">
    <div class="login-form">
            <div id="login">
              <h1>Login Information</h1>
              
              <form action="login.jsp" method="post">
              
                <div class="field-wrap">
                <label>
                  User ID<span class="req">*</span>
                </label>
                <input type="text" required autocomplete="off" name="id" value="<%= nvl(request.getParameter("id")) %>">
              </div>
              
              <div class="field-wrap">
                <label>
                  Password<span class="req">*</span>
                </label>
                <input type="password" required autocomplete="off" name="key" value="<%= nvl(request.getParameter("key")) %>">
              </div>
              
              <div class="field-wrap">
                <label>
                  Authorization<span class="req">*</span>
                </label>
                <input type="password" required autocomplete="off" name="code" value="<%= nvl(request.getParameter("code")) %>">
              </div>
              
              <p>&nbsp;</p>
              
              <button class="button button-block"/>Log In</button>
              
              </form>
            </div>
    </div>
</div>
</html>
