<script src="../assets/js/jquery.min.js"></script> 
<script>
    $(document).ready(function() {
        var myCount = 0;
        $(".license").keyup(function(){ $.fn.checkLicense(); });
        $("#license").keyup(function(){ $.fn.checkLicense(); });//TODO: 50_268 is the one that uses this
        $("#tpwd").keyup(function(){ $.fn.checkLicense(); }); 

        $.fn.checkLicense = function() {
            myCount = 0;
            $(".license").each(function(i, obj){
                if ($(this).prop("value") === "") myCount++;
            });
            if(myCount === 0){
                $("#licenseInfo").hide();   
            } else {
                $("#licenseInfo").show();   
            }
        }


    });//doc ready

</script>       