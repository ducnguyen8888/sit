</head>
<body>
    <header>
        <div id="hdrImg" style="background-image: url('images/logo-<%= nvl(session.getAttribute("imageName"), "act") %>.png');"></div>
        <div id="hdrTitle">Special Inventory Tax System</div>    
        <div class="hdrDiv">
            <div id="user-summary" > 
                <div id="user-name"><%= nvl(session.getAttribute("username"), "") %></div>
                <div id="system-date">&nbsp;</div>
                <div id="system-time">&nbsp;</div>
                <div id="connected-system-name">&nbsp;</div>
            </div>
        </div>  
        <div class="hdrDiv">
            <% if ( !readOnly ) {%>
            <div id="dealers"><i class="fa fa-car"></i><a href="dealerships.jsp">Dealerships</a></div>
            <div id="payments"><i class="fa fa-bank"></i><a href="paymentsDue.jsp">Payments Due</a></div>

            <%

                    // Display cart link if we have items in the cart
                    if( payments.size() > 0 )
                    {
                        %><div id="cart"><i class="fa fa-cart-arrow-down"></i><a href="pay.jsp">Cart</a></div><%
                    }
                }

            %>

            <div id="logout" ><i class="fa fa-sign-out"></i><a href="logout.jsp">Logout</a></div>

            <%
            // Display the help link if one exists for this page
            if ( isDefined(onlineHelpURL) )
            {
                %><div id="help" ><i class="fa fa-sign-out"></i><a href="<%= onlineHelpURL %>">help</a></div><%
            }
            %>

            <!-- <div id="feedback"><i class="fa fa-comment"></i><a id="<%= current_page %>" href="#">Feedback</a></div> -->
        </div>

        <% if( !readOnly ) { %>
        <div id="sidebarTitle" style="">Recent Dealerships</div>

        <%
            }
        // Display the dealership category name
        if ( ! "dealerships.jsp".equals(currentPage) && ! "feedback.jsp".equals(currentPage) && dealership != null )
        {
            %>
            <div id="navDiv" style="margin-top: 6px; font-size: 16px;">
                <%= categoryName %> Inventory
            </div>
            <%
        }
        %>
    </header>