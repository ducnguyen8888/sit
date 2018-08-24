<%@ page import="act.sit.*"
%><%@ include file="_configuration.inc"
%><%--
--%><%

    // Clear any possible session data
    ds.clear(); // prevents ghost record from showing up after failed and then successful login
    session.removeAttribute("sitAccount");


    // Expected Parameters by action:
    //
    //  Action:         Parameters:
    //  LOGIN           client  user    pin
    //  FORGOTPIN       client  user    email
    //  CHANGEPIN       client  user    newpin  cpin        One of: pin -or- resetId
    //

    String  clientId        = request.getParameter("client");
    String  userName        = request.getParameter("user");

    String  pin             = request.getParameter("pin");

    String  email           = request.getParameter("email");

    String  resetId         = request.getParameter("resetId");
    String  newpin          = request.getParameter("newpin");
    String  cpin            = request.getParameter("cpin");



    int     action          = LOGIN;
    if ( isDefined(newpin) )
    {   action = CHANGEPIN;
    }
    else if ( isDefined(email) )
    {   action = FORGOTPIN;
    }
//out.println(String.format("{ \"status\": \"err\", \"action\": \"%s\" }",act.util.Connect.getName(datasource)));
//if ( true ) return;

    if ( isDefined(clientId, userName) )
    {   try
        {   SITUser sitUser = new SITUser(datasource, clientId, userName, pin);
            switch ( action )
            {
                case  FORGOTPIN     :   // Timestamp the reset ID, allows us to easily and quickly exclude expired values
                                        //resetId = String.format("%s%d", (System.currentTimeMillis()+86400000), (long)(Math.random()*100000));
                                        resetId = String.format("%s%.15s", (System.currentTimeMillis()+86400000), session.hashCode());
                                        if ( sitUser.updateResetId(email,resetId) )
                                        {   sendPinResetEmail(pageContext, datasource, clientId, userName, email, resetId);
                                            out.println(String.format("{ \"status\": \"ok\", \"action\": \"ok\" }"));
                                        }
                                        else
                                        {   out.println(String.format("{ \"status\": \"ok\", \"action\": \"failed\" }"));
                                        }
                                        break;

                case  CHANGEPIN     :   boolean pinUpdated = false;
                                        if ( isDefined(newpin) && newpin.equals(cpin) && ! notDefined(pin,resetId) )
                                        {
                                            if ( isDefined(resetId) )
                                            {
                                                if ( resetId.compareTo(String.format("%s", System.currentTimeMillis())) < 0 )
                                                {   out.println(String.format("{ \"status\": \"ok\", \"action\": \"request has expired\" }"));
                                                    break;
                                                }
                                                pinUpdated = sitUser.resetPin(resetId, newpin);
                                            }
                                            else
                                            {
                                                sitUser.loadUserData();
                                                if ( sitUser.isValid() )
                                                {
                                                    pinUpdated = sitUser.changePin(newpin);
                                                }
                                            }

                                            if ( pinUpdated )
                                            {   out.println(String.format("{ \"status\": \"ok\", \"action\": \"ok\" }"));
                                            }
                                            else
                                            {   out.println(String.format("{ \"status\": \"ok\", \"action\": \"failed\" }"));
                                            }
                                        }
                                        else
                                        {   out.println(String.format("{ \"status\": \"ok\", \"action\": \"incomplete parameters\" }"));
                                        }
                                        break;

                case  LOGIN         :   //SITAccount sitAccount = new SITAccount(datasource, clientId, userName, pin);
                                        sitAccount = new SITAccount(datasource, clientId, userName, pin);
                                        if ( ! sitAccount.isValid() )
                                        {   throw new Exception("The username or password you entered is invalid");
                                        }

                                        sitUser = sitAccount.getUser();

                                        // PRC 190387: PIN change is required on the user's first login
                                        // This code is a fallback, pin change required should already be set
                                        if ( sitUser.getLastLoginTime() == null && ! sitUser.requiresPinChange() )
                                        {   sitUser.setPinChangeRequired();
                                        }

                                        if ( sitUser.isLocked() )
                                        {   throw new Exception("This user account is locked<br><br>Please contact the Tax Office for assistance");
                                        }

                                        if ( sitUser.requiresPinChange() )
                                        {   out.println(String.format("{ \"status\": \"ok\", \"action\": \"pinchange\" }"));
                                            break;
                                        }



                                        session.setAttribute("sitAccount", sitAccount);

                                        // The rest of these attributes are being set because that's what the rest
                                        // of the code is expecting. We need to re-write this and eliminate the
                                        // piece meal parameter settings and switch to a user/application control
                                        // object to simplify things (SITAccounts is that object...just need to use it)
                                        session.setAttribute("client_id", sitUser.getClientId());
                                        session.setAttribute("userid",    sitUser.getUserId());
                                        session.setAttribute("username",  sitUser.name);
                                        session.setAttribute("email",     sitUser.email);


                                        // Set the list of dealerships this account is associated with
                                        Dealerships _dealerships = new Dealerships();
                                        _dealerships.addAll(sitAccount.dealerships);
                                        session.setAttribute("dealerships",_dealerships);


                                        // This is a session object...we've not rewritten this class yet...
                                        // Note comment on client/client_id fields
                                        //      ...we need to investigate that further
                                        //      ...which is used where - and why two fields?
                                        payments.hashcode   = session.getId();
                                        payments.user       = sitUser.name;
                                        payments.username   = sitUser.name;
                                        payments.client     = sitUser.getClientId(); // I have both?
                                        payments.client_id  = sitUser.getClientId();



                                        // Are the only possible values "Y" or "N"?
                                        // Need to choose one of the following methods to set the preference value
                                        // Setting a session attribute should only be used until the rest of the application
                                        // is updated to use the SITAccount control object directly.
                                        session.setAttribute("finalize_on_pay", sitAccount.getPreference("SIT_FINALIZE_ON_PAY"));
                                        session.setAttribute("finalize_on_pay", (sitAccount.SIT_FINALIZE_ON_PAY ? "Y" : "N"));


                                        switch ( clientId )
                                        {   case "2000"         :   session.setAttribute("imageName", "harris");
                                                                    break;
                                            case "7580"         :   session.setAttribute("imageName", "dallas");
                                                                    break;
                                            case "79000000"     :   session.setAttribute("imageName", "fbc");
                                                                    break;
                                            case "94000000"     :
                                            case "94500000"     :   session.setAttribute("imageName", "elpaso");
                                                                    break;
                                            case "98000000"     :   session.setAttribute("imageName", "galveston");
                                                                    break;
                                            default             :   session.setAttribute("imageName", "act");
                                                                    break;
                                        }

                                        out.println(String.format("{ \"status\": \"ok\", \"action\": \"ok\",\"readOnly\":" + sitUser.readOnly()+"}"));
                                        break;
            }
        }
        catch (Exception error)
        {   out.println(String.format("{ \"status\": \"err\", \"detail\": \"%s\" }",
                                        error.getMessage().replaceAll("\\\n","<br>").replaceAll("\"","'")
                                        )
                        );
        }
        if ( true ) return;
    }

    out.println(String.format("{ \"status\": \"ok\", \"action\": \"invalid\" }"));
    if ( true ) return;

    // Determines what clients have users that can log into the system
    // Since this shouldn't change frequently we may want to set this
    // as an application value and retrieve only once - instead of every request
    //String[][] availableClients = SITAccount.getSITClients(datasource);
    //if ( availableClients.length == 0 )
    //{   errorMessage.append(String.format("No SIT user logins were found<br>%s (%s)", datasource,  act.util.Connect.getName(datasource)));
    //}
    //StringBuilder options = new StringBuilder();
    //Arrays.stream(availableClients).forEach(client -> options.append(String.format("<option value=\"%s\">%s</option>",client[0],client[1])));
    //String clientOptions = options.toString().replaceAll(String.format("(.*)(value=\"%s\")(.*)",clientId),"$1$2 selected$3");

%><%!
    final int     LOGIN           = 0;
    final int     FORGOTPIN       = 1;
    final int     CHANGEPIN       = 2;


    void replace(StringBuilder buffer, String textId, String replacement)
    {   int idx = 0;
        while ( (idx=buffer.indexOf(textId)) >= 0 )
            buffer.replace(idx, idx+textId.length(), replacement);
    }

%><%!
public void sendPinResetEmail(PageContext pageContext, String datasource, String clientId, String userName, String email, String resetId)
{
    javax.servlet.ServletContext          application = pageContext.getServletContext();
    javax.servlet.http.HttpServletRequest request     = (javax.servlet.http.HttpServletRequest)pageContext.getRequest();

    if ( isDefined(clientId, userName, email) )
    {   try (   Connection con = act.util.Connect.open(datasource);
                PreparedStatement ps = con.prepareStatement("select nvl(act_utilities.get_client_prefs(?,'INTERNET_PAYMENT_FROM_EMAIL'),'donotreply@lgbs.com') from dual");
            )
        {   String fromAddress = null;
            ps.setString(1, clientId);
            try ( ResultSet rs = ps.executeQuery(); )
            {   rs.next();
                fromAddress = rs.getString(1);
            }
            if ( notDefined(fromAddress) )
            {   throw new Exception("Invalid or missing from email address");
            }

            // Create and send the email
            String emailBody = null;
            StringBuilder buffer = new StringBuilder();
            String templateFile = request.getServletPath().replaceAll("^(.*)/[^/]*$","$1/login_reset_email.template");
            try ( BufferedReader in = new BufferedReader(new InputStreamReader(application.getResourceAsStream(templateFile))); )
            {   in.lines().forEach(line -> buffer.append(String.format("%s\n",line)));
                //buffer.delete(0,buffer.indexOf(String.format("//%s","END"))+5);

                // Build the postback URL the user will need to use
                String requestUrl = request.getRequestURL().toString().replaceAll("^([^/]*//)[^/]*(/.*)/[^/]*$","$1%s$2/%s%s");
                requestUrl = String.format(requestUrl, request.getHeader("HOST"), "login.jsp?accessid=", resetId);

                // Update our email text template to incorporate the postback URL and send
                replace(buffer, "[emailURL]", requestUrl);
                emailBody = buffer.toString();
                act.util.EMail.sendHtml(fromAddress,email,"SIT Portal Password Reset Request",emailBody);
            }
        }
        catch (Exception exception)
        {   SITLog.error(exception, String.format("Error sending email: %s",request.getRequestURI()));
        }
    }


    return;
}

%>
