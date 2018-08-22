    <form id="tabNav" action="yearlySummary.jsp" method="post">
        <input type="hidden" id="can" name="can" value="<%= can %>" />
        <input type="hidden" id="category" name="category" value="" />      
        <input type="hidden" id="year" name="year" value="" />  
    </form>
    <div id="helpDiv"></div>
    <footer id="footer">&copy;Appraisal &amp; Collection Technologies, LLC.</footer>

    <!-- jQuery and Bootstrap --> 
    <script src="assets/js/jquery.min.js"></script> 
    <script src="assets/js/bootstrap.min.js"></script>
    <script src="assets/js/jquery-ui.min.js"></script> 
    <script src="assets/js/various.js?<%= (new java.util.Date()).getTime() %>"></script>