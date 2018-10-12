<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 10/12/2018
  Time: 4:19 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc"%>
<script src="assets/js/jquery.min.js"></script>
<div>
    <form id="paymentForm">
        <input id="tid" name ="tid" namespace="TID"/>
        <input type="button" id="generate" value="Generate"/>
    </form>
</div>
<div id="result"></div>
<script>
    $(document).ready(function(){
        generateForm();
    })

    function generateForm(){
        $("#generate").click(function(e){
            e.preventDefault();
            e.stopPropagation();

            $.ajax({
                type:"POST",
                url:"paymentForm_ws.jsp",
                data:$("#paymentForm").serialize(),
                success:function(res){
                    $("#result").html("");
                    result = JSON.parse(res);
                    console.log(result.detail);
                    if ( result.generatePaymentFormRequest == "success"){
                        $("#result").append("<div>Client id: " + result.data.clientId+"</div>");
                        $("#result").append("<div>Tid: " + result.data.tid+"</div>");
                        $("#result").append("<div>Host: " + result.data.host+"</div>");
                        $("#result").append("<div>System report: " + result.data.systemReport+"</div>");
                        $("#result").append("<div>Form exists: " + result.data.formExists+"</div>");
                        if ( result.data.formExists == "false"){
                            $("#result").append("<div>Failure reason: "+result.data.failureReason+"</div>");
                        }
                        $("#result").append("<div>Report file name: " + result.data.reportFileName+"</div>");
                        $("#result").append("<div>Retrieval url: " + result.data.retrievalURL+"</div>");
                    } else {
                        $("#result").append("<div>"+ result.detail +"</div>");
                    }

                }
            })
        })
    }
</script>
