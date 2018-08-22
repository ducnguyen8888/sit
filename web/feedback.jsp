<%@ include file="_configuration.inc" %>

<%
    String pageTitle = "feedback";
    StringBuffer comment = new StringBuffer();
    String fromEmail = "";

    Connection connection = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // if (isDefined(request.getParameter("can"))){
    //     recents.add(request.getParameter("can"), request.getParameter("name"));
    // }

    if(isDefined(request.getParameter("comment"))){
      comment.append("Username: "  + nvl(session.getAttribute("username"), "") + "<br>"); 
      if (isDefined(request.getParameter("can"))) 
        comment.append("CAN: " + request.getParameter("can") + "<br>");  
      comment.append("Client ID: " + nvl(session.getAttribute("client_id"), "")+ "<br>");  
      comment.append("User ID: "   + nvl(session.getAttribute("userid"), "") + "<br>");
      comment.append("Current Page: "   + request.getParameter("current") + "<br>");
      
      if(ds.size() > 0) {
        try {
          d = new Dealership();
          comment.append("Dealer Accounts: ");
          for (int i = 0 ; i < ds.size() ; i++){
            d = (Dealership) ds.get(i);
            comment.append(nvl(d.can) + "&nbsp;&nbsp;");
          }
        } catch (Exception e) {
            comment.append("jac in the table loop: " + e.toString());
        }//try
      } else {
          comment.append("Sorry. No records found");
      }// if ds.size > 0
      comment.append("<br>Comment: " + nvl(request.getParameter("comment"), ""));


      connection = connect();

      try{    
          ps = connection.prepareStatement("select email from sit_users where client_id=? and userid=?");                                           
          ps.setString(1, nvl(session.getAttribute("client_id"), ""));
          ps.setString(2, nvl(session.getAttribute("userid"), ""));
          rs = ps.executeQuery();
          fromEmail = (rs.next()) ? rs.getString(1) : "test@lgbs.com";
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
      }

      // Send email
      try { 
          //                           from,           to,                subject,           body
          act.util.EMail.sendHtml( fromEmail, "jason.cook@lgbs.com", "SIT Feedback", comment.toString() );
      } catch (Exception em) { }

    }//if(isDefined(request.getParameter("comment")))


%>
<%@ include file="_top1.inc" %>
<style>
    #main table {margin-left:60px;}
    #dealerTable tr th { padding: 10px; border: 1px solid #808080; background: #c4cfdd;}
    #dealerTable tr td { padding: 10px; vertical-align: top;  background: #c4cfdd; border: 1px solid #808080;}
    #dealerTable tr td a { text-decoration: underline;}
    #dealerTable tr td a:hover { text-decoration: none;}
    #instruction{padding-top: 30px; padding-bottom: 30px; font-size: 1.2em;}
    #dealerTable tr > *:not(:last-child)  { border-right:none; }
    #dealerTable tr > *:not(:first-child) { border-left:none; }
    #dealerTable tr:nth-child(even) td { background:white; }
    #sideBar {bottom: 15px;}
    #body{top: 153px; margin:0px;}
</style>
<%@ include file="_top2.inc" %>
<%= recents  %><!-- include here for "recents" sidebar -->

    <div id="body">
        <div id="main" style="margin-top: 0px;">
            
            <% 
              if (isDefined(request.getParameter("comment"))){
                out.print("<div id=\"instruction\" style=\"padding-left: 50px;\">Thank you for your feedback.</div>");
              } else {
            %>
                <div id="instruction" style="padding-left: 50px;">Submit your feedback here</div>
                <form action="feedback.jsp">
                  <table id="dealerTable" style="margin-bottom: 20px;">
                    <tr>
                      <td>Comment:</td>
                      <td><textarea rows="6" cols="70" name="comment"></textarea></td>
                    </tr>
                    <tr>
                      <td>&nbsp;
                        <input type="hidden" name="current" value="<%= request.getParameter("current") %>">
                        <input type="hidden" name="can" value="<%= request.getParameter("can") %>">
                      </td>
                      <td><input type="submit" value="submit feedback"></td>
                    </tr>
                  </table>
                </form>
            <% } %>
        </div><!-- /main -->
    </div>



<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script>
      $(document).ready(function() {


          
      });
    </script>
</body>
</html>