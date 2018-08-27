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

<style>
    fieldset {  border-color: transparent; }
    #searchDealership { clear: both; position: relative; margin: 2rem auto auto auto; width: 58rem; height: 43rem; overflow: none;}
    #searchDealership .tabs.tab{ display: inline; clear: none; float: left; z-index: 4;}
    #searchDealership .tabs.tab:first-child label { border-bottom-left-radius: 6px;}
    #searchDealership .tabs.tab:last-child label { border-top-right-radius: 6px;}
    #searchDealership .tabs.tab label {
        display: table-cell; position: relative; z-index: 2;
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

    #searchDealership .tabs.tab input[type="radio"]:checked ~ label {
        font-style: italic; font-weight: bold; color: #A30000;
        background-color: whitesmoke;
        border-top: 2px solid black; border-bottom: 1px solid whitesmoke; border-right: 1px solid black; cursor: default;
    }

</style>

<fieldset>
    <legend align="center"><h1>Find Your DealerShip</h1></legend>
    <div id="searchDealership">
        <div id="tabs">
            <div class="tab">
                <div>Select Search Type:</div>
            </div>
            <div class="tab">
                <input type="radio"
                       id="accountSearch"
                       name="search-type"
                       value="number"
                       checked
                       aria-label="search by dealership number">
                <label for="accountSearch">Account Search</label>
                <div class="tabContent">
                    <form>
                        <h2>Search By Dealership Number</h2>
                        <div>
                            To select a different search type select from the tabs above
                        </div>
                        <div>
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
                        <div>
                            To select a different search type select from the tabs above
                        </div>
                        <div>
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
                       id="addressSearch"
                       name="search-type"
                       value="address"
                       aria-label="search by dealership address">
                <label for="addressSearch">Address Search</label>
                <div class="tabContent">
                    <form>
                        <h2>Search By Dealership Address</h2>
                        <div>
                            To select a different search type select from the tabs above
                        </div>
                        <div>
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
                       id="userNameSearch"
                       name="search-type"
                       value="username"
                       aria-label="search by login username">
                <label for="userNameSearch">Username Search</label>
                <div class="tabContent">
                    <form>
                        <h2>Search By Login Username</h2>
                        <div>
                            To select a different search type select from the tabs above
                        </div>
                        <div>
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
                       id="userIdSearch"
                       name="search-type"
                       value="id"
                       aria-label="search by login user id">
                <label for="userIdSearch">Id Search</label>
                <div class="tabContent">
                    <form>
                        <h2>Search By User Id</h2>
                        <div>
                            To select a different search type select from the tabs above
                        </div>
                        <div>
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