<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 8/28/2018
  Time: 10:58 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc" %>
<%!
    public StringBuffer getDealerAddress(Dealership d){
        StringBuffer sb = new StringBuffer();
        if (isDefined(d.nameline1)){sb.append(d.nameline1 );}
        if (isDefined(d.nameline2)){sb.append("<br>" + d.nameline2);}
        if (isDefined(d.nameline4)){sb.append("<br>" + d.nameline4);}
        sb.append("<br>" + nvl(d.city) + ", " + nvl(d.state));
        return sb;
    }

    public boolean AtLeastOneSpecified(String account,
                                       String name,
                                       String address,
                                       String userName,
                                       String id) {
        return ( isDefined(account)
                || isDefined(name)
                || isDefined(address)
                || isDefined(userName)
                || isDefined(id));
    }
%>
<%
    String pageTitle = "ViewDealership";
%>
<%@ include file="_top1.inc" %>
<%@ include file="_top2.inc" %>

<style>
    fieldset{ margin-top: 17rem;}
    legend{text-align: center; }
    #searchFields {
        clear: both;
        position: relative; margin: 2rem auto auto auto;
        border-radius: 5px;
        width: 120rem; background-color: whitesmoke;}
    #searchFields #no, #address, #userId  { margin-right: 2rem;}
    #searchFields #no { margin-left: 3rem;}
    #searchFields input { border: 1px solid black; border-radius: 3px; padding: 3px 8px 7px 8px; font-size: 12px;}

    .searchField { display: inline-block; margin-top: 4rem; margin-bottom: 4rem;}

    #searchBtn, #resetBtn {
        height:3rem; width: 6rem;
        background-color: #169BD7;
        color: white;
    }

    #searchBtn:hover, #resetBtn:hover{
        background-color: #253B80;
    }

    #dealersContainer{
        clear: both;
        position: relative; margin: 5rem auto 1rem auto;
        border-radius: 5px;
        width: 150rem; background-color: whitesmoke;
    }

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
        margin: 2rem auto 2rem 4rem;
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
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script>
    $(document).ready(function(){
        search();
        reset();
        getAccountDetail();
    })

    function search(){
        $("#searchBtn").click(function(e){
            e.preventDefault();
            e.stopPropagation();
            if (isAtLeastOneSpecified()) {
                $("#dealersContainer").empty();
                $("#searchDealers").submit();
            } else {
                $("#dealersContainer").html("<div style=\" text-align: center; color: red; font-size:15px;\">Please specify at least one of criteria</div>");
            }
        })
    }
    function reset(){
        $("#resetBtn").click(function(){
            $("#searchDealers")[0].reset();
            $("#dealersContainer").empty();
        })
    }

    function getAccountDetail(){
        console.log("Hello World");
        $("#dealersContainer div").click(function(e) {
            e.preventDefault();
            e.stopPropagation();
            var bigID = $(this).parent().attr("id").split("|");
            if(bigID[2] == undefined){
                bigID = $(this).attr("id").split("|");
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
    }

    function isAtLeastOneSpecified(){
        if ($('[name="no"]').val().length > 0
            || $('[name="name"]').val().length > 0
            || $('[name="address"]').val().length > 0
            || $('[name="userName"]').val().length > 0
            || $('[name="userId"]').val().length > 0){
            return true;
        } else {
            return false;
        }
    }
</script>
<%
    String dealershipNo         = nvl(request.getParameter("no"));
    String dealershipName       = nvl(request.getParameter("name"));
    String dealershipAddress    = nvl(request.getParameter("address"));
    String userName             = nvl(request.getParameter("userName"));
    String userId               = nvl(request.getParameter("userId"));

    ArrayList<Dealership> viewDealerships =  new ArrayList<Dealership>();;
    boolean atLeastOneSpecified           = AtLeastOneSpecified(dealershipNo, dealershipName, dealershipAddress, userName, userId);
    SearchCriteria criteria               = new SearchCriteria(dealershipNo, dealershipName, dealershipAddress, userName, userId);
    userId = "";
    if ( sitAccount.isValid()
            && sitAccount.getUser().viewOnly()
            && atLeastOneSpecified) {
        sitAccount.loadDealerships( criteria);
        viewDealerships = sitAccount.dealerships;
    }
%>
<fieldset>
    <legend><h1>Enter Your Search Criteria</h1></legend>
    <div id="searchFields">
        <form id="searchDealers" action="search.jsp" method="post">
            <div class="searchField" id="no">
                <input name="no" type="text"
                       size="20" maxlength="30"
                       placeholder="Dealer No" />
            </div>
            <div class="searchField" id="name">
                <input name="name" type="text"
                       size="20" maxlength="30"
                       placeholder="Dealer Name" />
            </div>
            <div class="searchField" id="address">
                <input name="address" type="text"
                       size="20" maxlength="60"
                       placeholder="Dealer Address"/>
            </div>
            <div class="searchField" id="userName">
                <input name="userName" type="text"
                       size="20" maxlength="30"
                       placeholder="Username" />
            </div>
            <div class="searchField" id="userId">
                <input name="userId" type="text"
                       size="20" maxlength="30"
                       placeholder="User ID" />
            </div>
            <div class="searchField">
                <input type="button" id="searchBtn" value="Search"/>
                <input type="button" id="resetBtn" value="Reset"/>
            </div>
        </form>
    </div>
</fieldset>

<div id="dealersContainer">
    <%
        if( viewDealerships.size()  > 0){
            try{
                d = new Dealership();
                for (int i = 0 ; i < viewDealerships.size() ; i++){
                    d = (Dealership) viewDealerships.get(i);
                    out.println("<div id= '"+ d.can +"|" + d.dealerType +"|"+ d.nameline1 +"' class='dealerWidget'>");
                    out.println("  <div class='wtitle'>" + nvl(d.can) + "</div>");
                    out.println("  <div class='wbody'>" + getDealerAddress(d) + "</div>");
                    out.println("</div>");
                }
                viewDealerships.clear();
            }catch (Exception e){
                SITLog.error(e, "\r\nProblem in table loop for dealerships.jsp\r\n");
            }
        } else if (atLeastOneSpecified ) {
            out.println("<div style=\"text-align: center; color:red; font-size:15px;\">Sorry. No records found</div>");
        }
    %>

</div>

<form id="navigation" action="yearlySummary.jsp" method="post">
    <input type="hidden" name="can" id="can" value="">
    <input type="hidden" name="name" id="name" value="">
    <input type="hidden" name="dealer_type" id="dealer_type" value="">
    <input type="hidden" name="current" id="current" value="<%= current_page %>">
</form>



<%@ include file="_bottom.inc" %>

