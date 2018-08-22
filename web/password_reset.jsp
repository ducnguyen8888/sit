<%--
    DN - PRC 190387 - 7/13/2017
        Prompt automatic password change upon first time logging in to the portal.
    DN - PRC 194625 - 12/6/2017
        Fixed bugs
--%><%@ include file="_configuration.inc" %>

<%

//@page import="java.util.Arrays"%>

     
        /*
        
accessid = $_GET['accessid'] || $_POST['accessid']
validAccessID = exists(accessid) AND not expired 
if validAccessID
    look up accessid
    if accessid matches and lastaccess was within 24 hours

        if REQPINCHNG = 'Y' //first time
            if lastpinchange is null
                if $_POST['pw2']{
                    update pin
                    set reqpinchng to null
                    update lastaccess w/time
                    set reset_id to null
                }
            end if
        else // current user
            if $_POST['pw2']{
                update pin
                set reqpinchng to null
                update lastaccess w/time
                set reset_id to null
            }
        end if

    end if // accessid matches
else
    message invalid access id    
end if // get accessid
        */

%>
<%
String pageTitle = "Password Reset";
    StringBuffer sb = new StringBuffer();
    StringBuffer errorMessage = new StringBuffer();
    errorMessage.append("");
    String accessid = nvl(request.getParameter("accessid"), "");
    boolean validAccessID = false;
    String reset_id = null;
    String reqpinchng = null;
    
	String new_reset_id = null;
	String client_id = null;
	String username = null;
	String pin = null;
	String error = null;
	
    Connection connection = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
	
    //PRC 190387 update the reset_id in database then use it to change the password for first time logging in 
    if( accessid == ""){
		accessid = nvl(session.getAttribute("reset_id"),"");
		client_id = nvl(session.getAttribute("client_id"),"");
		username = nvl(session.getAttribute("user_name"),"");
		pin = nvl(session.getAttribute("pin"),"");
		Calendar calendar = Calendar.getInstance();
		java.sql.Date currentDate = new java.sql.Date(calendar.getTime().getTime());
		
		try {
			connection = connect();
			
			ps = connection.prepareStatement("update sit_users "
											+" set reset_id = ?, lastaccess = ?"
											+"where client_id = ? and username = ?"
											+"	and pin = ?"
											);
			ps.setString(1,accessid);
			ps.setDate(2,currentDate);
			ps.setString(3,client_id);
			ps.setString(4,username);
			ps.setString(5,pin);
			
			ps.executeUpdate();
			
		
		} catch (Exception e){
			throw e;
		} finally {
			try {ps.close();} catch(Exception e){}
			ps = null;
			try {connection.close();} catch(Exception e){}
			connection = null;
		}
	}
if (true){
    try{


        connection = connect();


          try{ // get report_seq and status
              ps = connection.prepareStatement("select reset_id, reqpinchng from sit_users where reset_id = ?");
              ps.setString(1, accessid);
              rs = ps.executeQuery();
              if(rs.next()){
                reset_id = nvl(rs.getString(1), "");
                reqpinchng = nvl(rs.getString(2), "N");
                validAccessID = accessid.equals(reset_id);
              } 
          } catch (Exception e) {
               SITLog.error(e, "\r\nProblem getting reset id for password_reset.jsp\r\n");
          } finally {
              try { if (rs != null) rs.close(); } catch (Exception e) {  SITLog.error(e, "\r\nProblem closing rs for password_reset.jsp\r\n"); }
              rs = null;
              try { if (ps != null) ps.close(); } catch (Exception e) {  SITLog.error(e, "\r\nProblem closing ps for password_reset.jsp\r\n"); }
              ps = null;
          }// try get report_seq and status


        


            if(request.getParameter("pw2") != null){ // update password
                try{    
                    ps = connection.prepareStatement("update sit_users set PIN = ?, RESET_ID = ? where reset_id = ?");
                    ps.setString(1, request.getParameter("pw2"));
                    ps.setString(2, "");
					ps.setString(3, request.getParameter("reset_id"));
					 
                    
                    if (ps.executeUpdate() > 0){ //returns number of rows affected
                        if("true".equals(session.getAttribute("forwarded"))){
                            response.sendRedirect("login/" + session.getAttribute("client_url") + "?message=updated" );
                        } else {
                            response.sendRedirect("login.jsp?message=updated" );
                        }
                        
                    } else {
                        errorMessage.append( "There was a problem. Please try again."+"New password: "+ request.getParameter("pw2")+"Reset Id: "+  request.getParameter("reset_id")+ "accessid: "+ accessid);
                    }

                } catch (Exception e) { 
                    SITLog.error(e, "\r\nProblem doing update in password_reset.jsp\r\n");
                } finally {
                    try { ps.close(); } catch (Exception e) { }
                    ps = null;

                } 
            }//if pw2 != null

        

    } catch (Exception e) {
       SITLog.error(e, "\r\nProblem in big try catch on password_reset.jsp\r\n");
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception e) {  SITLog.error(e, "\r\nProblem closing rs for big try catch on password_reset.jsp\r\n"); }
        rs = null;
        try { if (ps != null) ps.close(); } catch (Exception e) {  SITLog.error(e, "\r\nProblem closing ps for big try catch on password_reset.jsp\r\n"); }
        ps = null;
        if (connection != null) {
            try { connection.close(); } catch (Exception e) { }
            connection = null;
        }
    }
}// if validAccessID
%>
<%@ include file="_top1.inc" %>
<!-- include styles here -->
<style>
    #loginDiv { width: 1080px; }
    #login, #forgot { float:left; margin-top: 80px; margin-left: 40px; margin-right: 0px; background: #f5f5f5; border: 1px solid #d3d3d3; 
             padding: 20px 30px; width: 400px; height: 370px; -webkit-border-radius: 10px; -moz-border-radius: 10px; border-radius: 10px; } 
    #instructions{ float:left; margin-top: 90px; margin-left: 30px; padding-left: 30px; padding-top: 20px; font-size: 1.2em; color: #005eb9; 
                   height: 350px; max-width: 420px; border-left: 1px solid #d3d3d3; } 
    .toggleText { float: left; font-size: 12px; }
    #sidebarTitle { display: none; }
    header {height: 120px;}
</style>
<%@ include file="_top2.inc" %>
<% if (validAccessID ){ %>
    <div id="loginDiv">
        <div id="main" style="margin-top: 80px;">

            <div id="login" class="form-group">
                <p style="font-size: 16px; font-weight: bold; margin-bottom: 25px;">Create new password:</p>
                <form action="password_reset.jsp" id="pwReset" method="post">
                    <div class="form-group">
                      <label for="pw1">Enter your new password:</label>
                      <input type="password" name="pw1" id="pw1" class="form-control" />
                    </div>
                    <div class="form-group">
                      <label for="pw2">For verification, re-enter your new password:</label>
                      <input type="password" name="pw2" ID="pw2" class="form-control" />
                    </div>
                    <input type="hidden" name="reset_id" value="<%= accessid %>" />
                    <button type="submit" id="pwBtn" class="btn btn-default pull-right">Submit</button>
                </form>
                <div class="toggleText"><a id="pwToggle">[show password]</a></div><br>
            </div><!-- login -->

            <div id="instructions">
                <div id="instrTitle">Create and verify your new password</div>
                <% if (isDefined(request.getParameter("message"))) out.print("<br><br><span style=\"color: red;\">Please log in to continue.</span>"); %>
                <!-- <span style="font-size: 10px;"><%= sb.toString() %></span> -->
                <span id="errors" style="font-size: 14px; color: red;"><%= errorMessage.toString() %></span>
            </div><!-- instructions -->
          
        </div><!-- /main -->
    </div>
<% } %>


<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script>
        $(document).ready(function() {

            var $pw1          = $("#pw1");      // L pw input field (used with pwToggle) 
            var $pw2          = $("#pw2");      // L pw input field (used with pwToggle) 
            var $pwToggle     = $("#pwToggle"); // L toggle pw     - L = login
            var $forgot       = $("#forgot");   // F container div - F = Forgot
            var $login        = $("#login");    // L container div
            var $instructions = $("#instructions #instrTitle"); // instructional text
            var $errors       = $("#errors");

            $pwToggle.on('click', function(){
                if($pw1.prop("type") === "text"){ 
                    $pw1.prop("type", "password");
                    $pw2.prop("type", "password");
                    $pwToggle.text("[show password]");
                } else {
                    $pw1.prop("type", "text");
                    $pw2.prop("type", "text");
                    $pwToggle.text("[hide password]");
                }
            });//pwToggle
          
            $("#pwBtn").on('click', function(e){
                e.preventDefault();
                e.stopPropagation();
                if ($pw1.prop("value") === $pw2.prop("value")){ // passwords match
                    $errors.text("");
                    $("#pwReset").submit();
                } else { // passwords don't match
                    $errors.text("Your entered passwords don't match.");
                }
            });
  
        });
    </script>
</body>
</html>