<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 10/12/2018
  Time: 4:19 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ include file="_configuration.inc"%>
<script src="assets/js/jquery.min.js"></script>
<style>
    .paymentForm{  margin: 15px auto 30px 15px;  }
    #paymentForm input { height: 25px; border: 1px solid;  border-radius: 3px;}
    #tid { width: 205px; }
    #generate, #reset{  width: 100px; color: white; border: 1px solid; background-color: 2f6299;}
    #result div {  margin: 10px; }
    #result div label { font-weight: bold;}
</style>

<div class="paymentForm">
    <form id="paymentForm">
        <input id="tid" name ="tid" type="number" placeholder="TID"/>
    </form>
    <input type="button" id="generate" value="Generate"/>
    <input type="button" id="reset" value="Reset"/>
</div>
<div id="result" ></div>
<script>
    $(document).ready(function(){
        generateForm();
        reset();
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
                        $("#result").append("<div><label>Client id:</label> " + result.data.clientId+"</div>");
                        $("#result").append("<div><label>Tid:</label> " + result.data.tid+"</div>");
                        $("#result").append("<div><label>Host:</label> " + result.data.host+"</div>");
                        $("#result").append("<div><label>System report:</label> " + result.data.systemReport+"</div>");
                        $("#result").append("<div><label>Text response:</label> " + result.data.response+"</div>");
                        $("#result").append("<div><label>Form exists:</label> " + result.data.formExists+"</div>");
                        if ( result.data.formExists == "false"){
                            $("#result").append("<div><label>Failure reason:</label> "+result.data.failureReason+"</div>");
                        }
                        $("#result").append("<div><label>Report file name:</label> " + result.data.reportFileName+"</div>");
                        $("#result").append("<div><label>Retrieval url:</label> " + result.data.retrievalURL+"</div>");
                    } else {
                        $("#result").append("<div>"+ result.detail +"</div>");
                    }

                }
            })
            $("#paymentForm")[0].reset();
        })
    }


    function reset(){
        $("#reset").click(function(){
            $("#paymentForm")[0].reset();
            $("#result").html("");
        })
    }
</script>
