<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 8/10/2018
  Time: 11:10 AM
  To change this template use File | Settings | File Templates.
--%>

<%@ page import="act.sit.*, java.util.*, java.sql.*, java.io.*"
%>
<%
    try {
        sendPinResetEmail(pageContext, "jdbc/sit","7580", "sdsit", "duc.nguyen@lgbs.com", "123456789");
    } catch (Exception e) {
        out.println(e.toString());
    }
%>
Send
<%!

    boolean   nvl(String val,  boolean def) { return ( isDefined(val) ? isTrue(val.trim()) : def ); }
    int       nvl(String val,  int     def) { try { return Integer.parseInt  (val.replaceAll("[^\\d.-]","")); } catch (Exception e) {} return def; }
    long      nvl(String val,  long    def) { try { return Long.parseLong    (val.replaceAll("[^\\d.-]","")); } catch (Exception e) {} return def; }
    double    nvl(String val,  double  def) { try { return Double.parseDouble(val.replaceAll("[^\\d.-]","")); } catch (Exception e) {} return def; }

    boolean isDefined(String... values)
    {   if ( values == null || values.length == 0 ) return false;
        for ( String value : values )
        {   if ( value == null || value.length() == 0 ) return false;
        }
        return true;
    }
    boolean notDefined(String... values)
    {   if ( values == null || values.length == 0 ) return true;
        for ( String value : values )
        {   if ( value != null && value.length() > 0 ) return false;
        }
        return true;
    }
    String nvl(String... values)
    {
        if ( values != null )
        {
            for ( String value : values )
            {
                if ( value == null ) continue;
                return value;
            }
        }

        return "";
    }
    String nvl(Object value, String def)
    {
        return (value == null || ! (value instanceof String) ? def : (String) value);

    }
    boolean isTrue(String value)
    {
        return value != null && value.toUpperCase().matches("(Y|YES|TRUE)");
    }


    void replace(StringBuilder buffer, String textId, String replacement)
    {   int idx = 0;
        while ( (idx=buffer.indexOf(textId)) >= 0 )
            buffer.replace(idx, idx+textId.length(), replacement);
    }


    public void sendPinResetEmail(PageContext pageContext, String datasource, String clientId, String userName, String email, String resetId) throws  Exception
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
        {   //SITLog.error(exception, String.format("Error sending email: %s",request.getRequestURI()));
            throw  exception;
        }
        }


        return;
    }

%>