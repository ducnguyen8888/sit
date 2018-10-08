<%--
     DN - 10/02/2018 - PRC 205088
            - Added CAD No
            - Display "CAD No" controlled by codeset "SHOW_CAD_NO_IN_SIT_PORTAL"
--%>
<%@ include file="_configuration.inc" %>
<%! 
    public StringBuffer getDealerAddress(Dealership d){
        StringBuffer sb = new StringBuffer();
        if (isDefined(d.nameline1)){sb.append(d.nameline1 );}
        //if (isDefined(d.nameline1)){sb.append("<a id = \"" + d.can + "\" class = \"" + d.dealerType + "\" href=\"#\">" + d.nameline1 + "</a>");}
        if (isDefined(d.nameline2)){sb.append("<br>" + d.nameline2);}
       // if (isDefined(d.nameline3)){sb.append("<br>" + d.nameline3);}
        if (isDefined(d.nameline4)){sb.append("<br>" + d.nameline4);}
        sb.append("<br>" + nvl(d.city) + ", " + nvl(d.state));
        //if (isDefined(d.phone)){sb.append("<br>Phone: " + formatPhone(d.phone));}
        //sb.append("<br>Acct: " + d.aprdistacc);
        return sb;
    }
%>
<%
    StringBuffer sb = new StringBuffer();
    String pageTitle = "Dealerships";
    //if (isDefined(request.getParameter("can"))){
    //    recents.add(request.getParameter("can"), request.getParameter("name"));
    //}
  
%>
<%@ include file="_top1.inc" %>
<style>
    #main table {margin-left:60px;}
    #instruction{padding-top: 30px; padding-bottom: 30px; font-size: 1.2em;}
    #sideBar {bottom: 15px;}
    #body{top: 153px; margin:0px;}

        .dealerWidget {
            border: 1px solid #165983;
            width:250px;
            height:112px;
            -webkit-border-radius:6px;
            -moz-border-radius:6px;
            border-radius:6px;/**/ 
            background:#C4CFDD;
            display:inline-block;
            vertical-align:top;
            margin-left:20px;
             -webkit-box-shadow:0 8px 6px -6px black;
            -moz-box-shadow:0 8px 6px -6px black;
            box-shadow:0 8px 6px -6px black;
            margin-bottom:20px;
        }
        .dealerWidget div.wtitle {
            background:#B4C4D9;
            padding-left: 10px;
            font-size: 14px;
            font-weight: bold;
            text-align:left;
            height:30px; 
            padding-top:6px; 
            margin-bottom:5px; 
            -webkit-border-radius:4px; 
            -moz-border-radius:4px; 
            border-radius:4px; 
            border-bottom: solid 1px #165983;
            overflow:hidden;
            text-overflow: clip;
            text-overflow: ellipsis;
            text-overflow: "…";
        }
        .dealerWidget div.wtitle span {
            float: right;
            margin-right: 10px;
        }
        .dealerWidget div.wbody { 
            padding: 0px 10px 10px 10px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: clip;
            text-overflow: ellipsis;
            text-overflow: "…";
        }
        .dealerWidget:hover{background:#e6e6e6; cursor: pointer;}
</style>
<%@ include file="_top2.inc" %>
<%= recents %><!-- include here for "recents" sidebar -->

    <div id="body">
        <div id="main" style="margin-top: 0px;">
            <div id="instruction" style="padding-left: 50px;">Please select the dealership you wish to file for</div>
			

<div id="dealersContainer">
  <%
      if(ds.size() > 0){
          try{
              d = new Dealership();
              for (int i = 0 ; i < ds.size() ; i++){
                  d = (Dealership) ds.get(i);
                  out.println("<div id= '"+ d.can +"|" + d.dealerType +"|"+ d.nameline1 +"' class='dealerWidget'>");
                  out.println("  <div class='wtitle'>" + nvl(d.can) +( sitAccount.SHOW_CAD_NO_IN_SIT_PORTAL ? ("<span>CAD No: "+d.aprdistacc+"</span>") : "") + "</div>");
                  out.println("  <div class='wbody'>" + getDealerAddress(d) + "</div>");
                  out.println("</div>");
              }
          }catch (Exception e){
              SITLog.error(e, "\r\nProblem in table loop for dealerships.jsp\r\n");
          }
      } else {
          out.println("<tr><td colspan=\"3\" style=\"text-align: center;\">Sorry. No records found</td></tr>");
      }
  %>       

</div>
<% if(session.getAttribute("client_id").equals("7580")){%>
		<div style="color: red;" align="center">
			<Strong><i>Note: Any months filed and paid by mail or in person will not be reflected on the portal.</i></Strong>
		</div>
<% } %>

        </div><!-- /main -->
    </div>
    <form id="navigation" action="yearlySummary.jsp" method="post">
        <input type="hidden" name="can" id="can" value="">
        <input type="hidden" name="name" id="name" value="">
        <input type="hidden" name="dealer_type" id="dealer_type" value="">
        <input type="hidden" name="current" id="current" value="<%= current_page %>">
    </form>


<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script>
      $(document).ready(function() {
          var finalize_on_pay = ("<%= session.getAttribute("finalize_on_pay") %>" === "Y");
          console.log("js finalize_on_pay: " + finalize_on_pay);
          console.log("j session  finalize_on_pay: " + "<%= session.getAttribute("finalize_on_pay") %>");
          console.log("j variable finalize_on_pay: " + "<%= finalize_on_pay %>");

          //$("table#dealerTable a").click(function(e) {
          //    e.preventDefault();
          //    e.stopPropagation();
          //    var can = $(this).attr("id");
          //    var dealer_type = $(this).attr("class");
          //    var name = $(this).text();
          //    var theForm = $("form#navigation");
          //    theForm.children("input#can").prop("value", can);
          //    theForm.children("input#dealer_type").prop("value", dealer_type);
          //    theForm.children("input#name").prop("value", name);
          //    theForm.submit();
          //});
          $("#dealersContainer div").click(function(e) {
              e.preventDefault();
              e.stopPropagation();
              var bigID = $(this).parent().attr("id").split("|");
              //console.log("can: " +bigID[0] + ", type: " + bigID[1]+ ", name: " +bigID[2] );
              if(bigID[2] == undefined){
                //console.log("it was undefined");
                bigID = $(this).attr("id").split("|");
                //console.log("again...can: " +bigID[0] + ", type: " + bigID[1]+ ", name: " +bigID[2] );
              }
              var can         = bigID[0];
              var dealer_type = bigID[1];
              var name        = bigID[2];
              var theForm = $("form#navigation");
              theForm.children("input#can").prop("value", can);
              theForm.children("input#dealer_type").prop("value", dealer_type);
              theForm.children("input#name").prop("value", name);
              theForm.submit();
          });
          
          $("table#recentsTable a").click(function(e) {
              e.preventDefault();
              e.stopPropagation();
              var can = $(this).text();
              var dealer_type = $(this).attr("class");
              var name = $(this).parent().children("#sidebarRecent").text();
              var theForm = $("form#navigation");
              theForm.children("input#can").prop("value", can);
              theForm.children("input#dealer_type").prop("value", dealer_type);
              theForm.children("input#name").prop("value", name);
              theForm.submit();
          });          
          $("#feedback a").click(function(e) {
              e.preventDefault();
              e.stopPropagation();
              var theForm = $("form#navigation");
              theForm.prop("method", "post");
              theForm.prop("action", "feedback.jsp");
              theForm.submit();
          });   



      });
    </script>
</body>
</html>