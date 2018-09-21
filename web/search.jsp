<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 8/28/2018
  Time: 10:58 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc" %><%
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
        height: 3rem;
        width: 6rem;
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

    .warning{ text-align: center; color: red; font-size:15px; }
    .searching{ text-align: center; font-size: 15px; }

    #footer{
        position: fixed;
    }



</style>
<script>
    $(document).ready(function(){
        search();
        getAccountDetail();
        reset();

        function search(){
            $("#searchBtn").click(function(e){
                e.preventDefault();
                e.stopPropagation();
                if (isAtLeastOneSpecified()) {
                    $("#dealersContainer").empty();
                    $("#dealersContainer").html("<div class='searching'>Searching, please wait...</div>");
                    $.ajax({
                        type:'POST',
                        url:'search_ws.jsp',
                        data: $("#searchDealers").serialize(),
                        success: function(res){
                            $(".searching").remove();
                            var dealerContainer = JSON.parse(res);
                            if (dealerContainer.searchDealershipsRequest=="success") {
                                if (dealerContainer.data.searchDealerships == "success") {
                                    if (dealerContainer.data.dealerships.length > 0) {
                                        loadDealerships(dealerContainer.data.dealerships);
                                    } else {
                                        $("#dealersContainer").html("<div class='warning'>Sorry. No records found</div>");
                                    }
                                } else {
                                    $("#dealersContainer").html("<div class='warning'>An error just occurred. Please try again</div>");
                                }
                            } else {
                                $("#dealersContainer").html("<div class='warning'>"+dealerContainer.detail+"</div>");
                            }
                        },
                        error: function(){
                            $(".searching").remove();
                            $("#dealersContainer").html("<div class='warning'>An error just occurred. Please try again</div>");
                        }

                    })
                    $("#searchDealers")[0].reset();
                } else {
                    $("#dealersContainer").html("<div class='warning'>Please specify at least one of criteria</div>");
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
            $("#dealersContainer").on('click','.dealerWidget', function(e){
                e.preventDefault();
                var bigID = $(this).attr("id").split("_");
                var can         = bigID[0];
                var dealer_type = bigID[1];
                var theForm = $("form#navigation");
                theForm.children("input#can").prop("value", can);
                theForm.children("input#dealer_type").prop("value", dealer_type);
                theForm.submit();
            })

        }


        function loadDealerships(dealerships){
            for ( i=0; i<dealerships.length; i++){
                var dealerId = dealerships[i].can+"_"+dealerships[i].dealerType;
                $("#dealersContainer").append("<div id='"+ dealerId +"'class='dealerWidget'>");
                $("#dealersContainer #"+ dealerId).append("<div class='wtitle'>"+ dealerships[i].can + "</div>");
                $("#dealersContainer #"+ dealerId).append("<div class='wbody'>"+ getAddress(dealerships[i]) +"</div>");
                $("#dealersContainer").append("</div>");
            }
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

        function getAddress(dealership){
            return dealership.nameline1
                  + nvl(dealership.nameline2)
                  + nvl(dealership.nameline4)
                  + "<br>"
                  + dealership.city+","
                  + dealership.state ;
        }

        function nvl(value){
            if ( value !==null
                && value !==""){
                return "<br>"+value;
            } else {
                return "";
            }
        }

    });
</script>
<fieldset>
    <legend><h1>Enter Your Search Criteria</h1></legend>
    <div id="searchFields">
        <form id="searchDealers">
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
                <input class="btn btn-primary" type="button" id="searchBtn" value="Search"/>
                <input class="btn btn-primary" type="button" id="resetBtn" value="Reset"/>
            </div>
        </form>
    </div>
</fieldset>

<div id="dealersContainer"></div>

<form id="navigation" action="yearlySummary.jsp" method="post">
    <input type="hidden" name="can" id="can" value="">
    <input type="hidden" name="name" id="name" value="">
    <input type="hidden" name="dealer_type" id="dealer_type" value="">
    <input type="hidden" name="current" id="current" value="<%= current_page %>">
</form>



<%@ include file="_bottom.inc" %>

