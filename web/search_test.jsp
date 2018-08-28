<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 8/24/2018
  Time: 10:55 AM
  To change this template use File | Settings | File Templates.
--%>

<%@ include file="_configuration.inc" %>
<%
    String pageTitle = "ViewDealership";
%>
<%@ include file="_top1.inc" %>
<%@ include file="_top2.inc" %>
<style>
    fieldset { margin-top: 20rem; border-color: transparent; xbackground-color: cyan;}
    fieldset h1{  font-family: Arial, Helvetica, sans-serif; font-weight: bold; font-size: 3rem; text-align: center;}
    legend { margin: 0 auto; }
    #searchDealership { clear: both; position: relative; margin: 2rem auto auto auto; width: 68rem; height: 53rem; overflow: none; xborder: 1px solid red;}

    #searchDealership div.content{
        position: absolute; top: 2rem; bottom: 20rem; width: 100%;
        background-color: whitesmoke;  border: 1px solid black;
        border-top-right-radius: 8px 8px; border-bottom-right-radius: 6px; border-bottom-left-radius: 6px;
    }

    #searchDealership div.tab{ display: inline; clear: none; float: left; z-index: 4;}
    #searchDealership div.tab input[type="radio"]{ visibility: hidden; position: absolute; z-index: -1;}
    #searchDealership div.tab:first-child label { border-bottom-left-radius: 6px;}
    #searchDealership div.tab:last-child label { border-top-right-radius: 6px;}

    #searchDealership div.tab label {
        display: table-cell; position: relative; z-index: 2;
        height: 1rem; width: 10rem; max-width: 10rem; padding: .6rem .3rem .3rem .3rem;
        font-family: Arial, Helvetica, sans-serif; font-weight: bold; text-align: center; font-size: 0.8rem; line-height: 1.0rem;
        background-color: midnightblue;
        background: -webkit-gradient(linear, left top, left bottom, from(midnightblue), to(#0078a5));
        background: -moz-linear-gradient(top,  midnightblue,  #0078a5);
        background: -webkit-linear-gradient(top,  midnightblue,  #0078a5);
        background: linear-gradient(to bottom,  midnightblue 0%,#0078a5 100%); /* W3C, IE10+, FF16+, Chrome26+, Opera12+, Safari7+ */
        background: -ms-linear-gradient(to bottom,  midnightblue 0%,#0078a5 100%);
        filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='midnightblue', endColorstr='#0078a5',GradientType=0 ); /* IE6-9 */
        color: whitesmoke; border: 1px solid midnightblue;
    }

    #searchDealership div.tab input[type="radio"] ~ label {
        font-weight: normal; text-align: center; font-size: 1.0rem; line-height: 1.0rem;
        background: none; background-color: darkgrey; color: black;
        border-left-color: whitesmoke;
    }

    #searchDealership div.tab input[type="radio"]:not(:checked) ~ label:hover{
        background-color: dimgrey; color: whitesmoke; cursor: pointer;
    }

    #searchDealership div.tab input[type="radio"]:checked ~ label {
        font-style: italic; font-weight: bold; color: #A30000;
        background-color: whitesmoke;
        border-top: 2px solid black; border-bottom: 1px solid whitesmoke; border-right: 1px solid black; cursor: default;
    }

    #searchDealership div.tab input[type="radio"] ~ div.tabContent{
        display: none; position: absolute; left: 0px; right: 0px; bottom: 0px; top: 2.5rem;
        padding: 1rem; text-align: center; font-size: 1.0rem;
    }

    #searchDealership div.tab input[type="radio"]:checked ~ div.tabContent{
        display: block;
    }

    #searchDealership div.tab input[type="radio"] ~ div.tabContent h2{ font-size: 22px;}

    #searchDealership .searchInput {
        margin: 0; padding: 5px 10px; width: 25rem;
        font-family: Arial, Helvetica, sans-serif; font-size: 1.1rem;
        border:1px solid #0076a3; border-right:0px; border-top-left-radius: 6px; border-bottom-left-radius: 6px;
        background: white; outline: none;
    }

    #searchDealership .searchBtn{
        margin: 0; padding: 5px 15px;
        font-family: Arial, Helvetica, sans-serif; font-size:14px; font-size: 1.1rem; color: #ffffff;
        outline: none; cursor: pointer; text-align: center; text-decoration: none;
        border: solid 1px #0076a3; border-right:0px; border-top-right-radius: 4px; border-bottom-right-radius: 4px;
        background-color: midnightblue;
        background: -webkit-gradient(linear, left top, left bottom, from(midnightblue), to(#0078a5));
        background: -moz-linear-gradient(top,  midnightblue,  #0078a5);
        background: -webkit-linear-gradient(top,  midnightblue,  #0078a5);
        background: linear-gradient(to bottom,  midnightblue 0%,#0078a5 100%);
        background: -ms-linear-gradient(to bottom,  midnightblue 0%,#0078a5 100%);
        filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='midnightblue', endColorstr='#0078a5',GradientType=0 );
    }

    #searchDealership .searchBtn:hover{
        background-color: #00adee;
        background: -webkit-gradient(linear, left top, left bottom, from(#00adee), to(#0078a5));
        background: -moz-linear-gradient(top,  #00adee,  #0078a5);
        background: -webkit-linear-gradient(top,  #00adee,  #0078a5);
        background: linear-gradient(to bottom,  #00adee 0%,#0078a5 100%);
        background: -ms-linear-gradient(to bottom,  #00adee 0%,#0078a5 100%);
        filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#00adee', endColorstr='#0078a5',GradientType=0 );
    }

    #searchDealership div.tabContent { color: midnightblue; font-family: Arial, Helvetica, sans-serif; font-size: 1.4rem; }
    #searchDealership div.tabContent h2 { font-size: 1.7rem; font-weight: bold; clear: both; margin: 3rem 0px 15px 0px; color: #A30000;}

    #searchDealership .searchCriteria { margin: 2.2rem;}
    #searchDealership div.tabContent div.searchNote{ clear: both; margin-bottom: 25px; color: black; font-style: italic; font-weight: bold; }

    #searchDealership div.tab .anchor {
        display: table-cell; position: relative; z-index: 1; border-top-left-radius: 6px;
        height: 1.2rem; width: 13rem; max-width: 13rem; text-align: right; padding: 10px 10px 2px 5px;
        font-family: Arial, Helvetica, sans-serif; font-weight: bold; font-size: 1.0rem; line-height: 1.0rem;
        background-color: midnightblue;
        color: whitesmoke; border: 1px solid midnightblue;
    }


</style>

<fieldset>
    <legend><h1>Find Your Dealership</h1></legend>
    <div id="searchDealership">
        <div class="content"></div>
        <div id="tabs">
            <div class="tab">
                <div class="anchor">Select Search Type:</div>
            </div>
            <div class="tab">
                <input type="radio"
                       id="accountSearch"
                       name="search-type"
                       value="number"
                       checked
                       aria-label="search by dealership account number">
                <label for="accountSearch">Account Search</label>
                <div class="tabContent">
                    <form>
                        <h2>Search By Dealership Account Number</h2>
                        <div class="searchNote">
                            To select a different search type select from the tabs above
                        </div>
                        <div class="searchCriteria">
                            <input class="searchInput"
                                   placeholder="Enter your search here"
                                   name="criteria"
                                   size="20" maxlength="120">
                            <input class="searchBtn"
                                   type="submit"
                                   value="search">
                        </div>
                    </form>
                </div>
            </div>

            <div class="tab">
                <input type="radio"
                       id="nameSearch"
                       name="search-type"
                       value="name"
                       aria-label="search by dealership name">
                <label for="nameSearch">Name Search</label>
                <div class="tabContent">
                    <form>
                        <h2>Search By Dealership Name</h2>
                        <div class="searchNote">
                            To select a different search type select from the tabs above
                        </div>
                        <div class="searchCriteria">
                            <input class="searchInput"
                                   placeholder="Enter your search here"
                                   name="criteria"
                                   size="20" maxlength="120">
                            <input class="searchBtn"
                                   type="submit"
                                   value="search">
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</fieldset>

<%@ include file="_bottom.inc" %>