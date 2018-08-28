<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 8/28/2018
  Time: 10:58 AM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc" %>
<%
    String pageTitle = "ViewDealership";
%>
<%@ include file="_top1.inc" %>
<%@ include file="_top2.inc" %>

<style>
    fieldset{ margin-top: 17rem;}
    #searchFields {
        clear: both;
        position: relative; margin: 2rem auto auto auto;
        border-radius: 5px;
        width: 120rem; background-color: whitesmoke;}
    #searchFields #no, #address, #userId  { margin-right: 2rem;}
    #searchFields #no { margin-left: 3rem;}
    #searchFields input { border: 1px solid black; border-radius: 3px; padding: 3px 8px 7px 8px; font-size: 12px;}

    .searchField { display: inline-block; margin-top: 4rem; margin-bottom: 4rem;}

</style>

<fieldset>
    <legend>Enter Your Search Criteria</legend>
    <div id="searchFields">
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
    </div>
</fieldset>
<%@ include file="_bottom.inc" %>