app.controller("MailProcessController",
                ['$scope','$rootScope','$log','$location',
                '$timeout','$http',
                'paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,
            $timeout,$http,
            paymentFactory,errorManager) {
	$log.debug("Mail Process Controller: Loaded");




	$log.debug("Mail Process Controller: Payment data loading");
	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("Mail Process Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;
	$log.debug("Mail Process Controller: Payment data loaded");


    $scope.application      = $rootScope.application;
    $scope.config = $rootScope.config;
	if ( ! $scope.config ) {
		$log.error("Mail Process Controller: Failed to locate configuration");
		errorManager.raiseDataError();
		return;
	}


    // Verify current payment status. 
    if ( $scope.payment.status != $scope.status.VERIFIED ) {
        if ( $scope.payment.status == $scope.status.SUCCESS ) {
            $log.debug("Mail Process Controller: Payment successful, redirecting");
            $location.path($scope.pages.SUCCESS);
            return;
        }
        if ( $scope.payment.status == $scope.status.FAILURE ) {
            $log.debug("Mail Process Controller: Payment rejected, redirecting");
            $location.path($scope.pages.FAILURE);
            return;
        }

        // No other states should be directed to this page
        $log.error("Mail Process Controller: Unexpected status: " + $scope.payment.status);
        errorManager.raiseStateError();
        return;
    }
    $scope.payment.status = $scope.status.PROCESSING;
    $log.debug("Mail Process Controller: Processing payment");


    // Since the payment has been verified by the user we're not going
    // to bother checking for any outstanding errors. That's the job the Verify page.

    $scope.paymentParameters = null;
    $scope.setPaymentParameters = function () {
        $log.debug("Mail Process Controller: Setting payment parameters");
        var results = [];
        results.push("clientId="+$rootScope.config.clientId);
        for ( var key in $scope.payment.contact ) {
            if ( key == "errors" ) continue; 
            //$log.debug("--> contact parameter (" + key + ")");
            results.push(encodeURIComponent(key)+"="+encodeURIComponent($scope.payment.contact[key]));
        }
        for ( var key in $scope.payment.amount ) {
            if ( key == "errors" ) continue;
            //$log.debug("--> amount  parameter (" + key + ")");
            results.push(encodeURIComponent(key)+"="+encodeURIComponent($scope.payment.amount[key]));
        }

        for ( var i=0; i < $scope.payment.accounts.length; i++ ) {
            if ( ! $scope.payment.accounts[i].paymentAmount || $scope.payment.accounts[i].paymentAmount <= 0 ) continue;

            var field = encodeURI( $scope.payment.accounts[i].account + "|" 
                            + ($scope.payment.accounts[i].report ? $scope.payment.accounts[i].report : "") + "|"
                            + ($scope.payment.accounts[i].year ? $scope.payment.accounts[i].year : "") + "|"
                            + ($scope.payment.accounts[i].month ? $scope.payment.accounts[i].month : "") + "|"
                            + $scope.payment.accounts[i].paymentAmount
                            );
            results.push("account=" + field);
        }
        $scope.paymentParameters = results.join("&");
        $log.warn("Payment Parameters:\n" + $scope.paymentParameters);
    }
    $scope.serializeObject = function(obj) {
        var result = [];
        for ( var key in obj ) 
            result.push(encodeURIComponent(key)+"="+encodeURIComponent(obj[key]));
        return result.join("&");
    }
    $scope.setPaymentParameters();


    // ////////////////////////
    // Set maximum processing time limit so the user isn't left in limbo
    // ////////////////////////

    // This is used to set a maximum limit to how long we'll make the
    // user wait and guess what's going on. If the request returns 
    // before we time out we'll cancel the timer.
    $scope.timeoutPromise = $timeout(function() { $scope.transactionWaitLimit($scope.payment,$scope.pages,$scope.status); },15000);
    $scope.transactionWaitLimit = function(payment,pages,status) {
        if ( ! payment || ! pages || ! status ) return;

        $log.debug("Mail Process Controller: Process time limit exceeded, checking status");
        if ( payment.status == status.PROCESSING ) {
            $log.debug("Mail Process Controller: Process time limit exceeded, payment is still processing. Redirecting to " + pages.ERROR);
            errorManager.raiseError("Processor Payment Error",
                        "Unable to Record your Payment Information",
                        "It is taking longer than expected to record your payment "
                        + "information. "
                        + "This delay may be due to unusually high payment volume. "
                        + "Please try again later.",
                        "", true
                    );
            return;
        }
        $log.debug("Mail Process Controller: Process time limit exceeded, payment status is not processing " + payment.status + ". It's not processing so we're abandoning this check");
    }

    // ////////////////////////
    // Save payment information
    // ////////////////////////
    $scope.savePaymentInformation = function () {
        $log.debug("Mail Process Controller: Recording payment information");

        $scope.paymentParameters = $scope.paymentParameters; 
        $log.debug(JSON.stringify($scope.paymentParameters));
        $scope.processingStatus = "Recording your payment information...";

        $scope.payment.reference = {};

        $http({
            method: "POST",
            url: $rootScope.config.urls.vendorPayment.Mail,
            data: $scope.paymentParameters,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}

            }).then(function(response) {
                $log.debug("Payment save response received. Response status: " + (response.status ? response.status : "No status in response"));
                if ( ! response.status ) $log.debug(JSON.stringify(response));
                $scope.processorFinished(response);
            },function errorCallBack(response) {
                $log.error("Mail Process Controller: Server returned an error status - ("
                                + response.status + ")");
                $log.debug(JSON.stringify(response.data));
                $timeout.cancel($scope.timeoutPromise);

                errorManager.raiseError("Payment Submission Failure",
                            "An error occurred when preparing your payment",
                            "The server responded with a " + response.status 
                                + " error while processing<br>your payment information. "
                                + "<br><br>No payment was made."
                                + "<br><br>Please try again later.",
                            response.statusText
                        );
                return;
            });
    };
    $scope.savePaymentInformation();


    // ////////////////////////
    // Verify processor results
    // ////////////////////////
    $scope.processorFinished = function (response) {
            $log.debug("Mail Process Controller: Analyzing payment processing response");
            $log.debug("Response: " + JSON.stringify(response.data));

            $timeout.cancel($scope.timeoutPromise);
            /*
{ "status": "success",
                "data": {
                    "status": "success",
                    "tid":    "454", 
                    "detail": "Payment was successfully created",
                    "reportURL": "/dev60temp/sitpbm_1538818425004.pdf",
                    "datetime": ""
                    }
                }
                */
            $scope.payment.response = response.data;
            $scope.payment.reference.status     = response.data.status;


            // HTTP failure: typically a server or network error
            if ( response.status != 200 ) // HTTP OK
            {
                $log.debug("Mail Process Controller: Response status: " + response.data.status);
                $scope.payment.status = $scope.status.FAILURE;

                $scope.processingStatus = "Processing failure";
                $scope.payment.reference.detail = "Processing response HTTP status: " + response.status;
                errorManager.raiseError("Report Creation Failure",
                            "Failed to create payment report",
                            "Report creation failed due to a processing error, please try again later",
                            "Processing results indicated a HTTP error status or server error"
                            );
                return;
            }

            // Response error: request was valid (HTTP-wise) but the response isn't in the
            // format we expected. We may have called the wrong page or development output
            // is still enabled.
            if ( ! response.data || ! ["success", "fail", "error"].includes(response.data.status) )
            {
                $log.debug("Mail Process Controller: Response status: " + response.data.status);
                $scope.payment.status = $scope.status.FAILURE;

                $scope.processingStatus = "Processing failure";
                $scope.payment.reference.detail = "Processing response status: " + response.status;
                errorManager.raiseError("Report Creation Failure",
                            "Failed to create payment report",
                            "Report creation failed due to a processing error, please try again later",
                            "Processing results indicated an error status or server error"
                            );
                return;
            }


            // Execution error: Page execution encountered a processing error. Possible SQL problem
            // or report server communication issue.
            if ( response.data.status == "error" )
            {
                $log.debug("Mail Process Controller: Response status: " + response.data.status);
                $scope.payment.status = $scope.status.FAILURE;
                if ( ! response.data.data )
                {
                    $scope.payment.reference.description = "Report creation failed due to a processing error, "
                                                            + "please try again later";
                    $scope.payment.reference.detail = "Unknown cause";
                }
                else
                {
                    $scope.payment.reference.description = response.data.data.description 
                                || "Report creation failed due to a processing error, please try again later";
                    $scope.payment.reference.detail = response.data.data.detail || "Unspecified error";
                }

                $scope.processingStatus = "Processing failure";

                errorManager.raiseError("Report Creation Error",
                            "Failed to create payment report",
                            $scope.payment.reference.description,
                            $scope.payment.reference.detail
                            );
                return;
            }


            // Execution failure: Failed to save payment data and generate report. Most likely a 
            // report creation issue.
            if ( response.data.status == "fail" )
            {
                $log.debug("Mail Process Controller: Response status: " + response.data.status);
                $scope.payment.status = $scope.status.FAILURE;
                if ( ! response.data.data )
                {
                    $scope.payment.reference.description = "Report creation failed due to a processing error, "
                                                            + "please try again later";
                    $scope.payment.reference.detail = "Unknown cause";
                }
                else
                {
                    $scope.payment.reference.detail = response.data.data.detail || "Unspecified error";
                }

                $scope.processingStatus = "Processing failure";

                errorManager.raiseError("Report Creation Failure",
                            "Failed to create payment report",
                            "Report creation failed due to a processing error, please try again later",
                            $scope.payment.reference.detail
                            );
                return;
            }




            // Check payment status
            $log.debug("Mail Process Controller: Verifying payment status");
            if ( response.data.status == "success" && response.data.data.status == "success" ) {
                $log.debug("Mail Process Controller: Payment was successful, reference: " 
                            + JSON.stringify(response.data.data));

                $scope.payment.status = $scope.status.SUCCESS;

                $scope.payment.reference.tid        = response.data.data.tid;
                $scope.payment.reference.reportURL  = response.data.data.reportURL;
                $scope.payment.reference.detail     = response.data.data.detail;
                $scope.payment.reference.datetime   = response.data.data.datetime;


                $log.debug("Mail Process Controller: TID " + $scope.payment.reference.tid);
                $log.debug("Mail Process Controller: URL " + $scope.payment.reference.reportURL);

                $location.path($scope.pages.SUCCESS);

                // Attempt to clear the cart of any payments
                $scope.clearPaymentCart();
                return;
            }




            // We shouldn't get to this point, if we do then something is very, very wrong
            $scope.payment.status = $scope.status.FAILURE;
            $scope.processingStatus = "Processing failure";
            errorManager.raiseError("Report Creation Error",
                        "Unexpected or unhandled response",
                        "Report creation failed due to a processing error, please try again later",
                        "Execution response parse failed, unexpected or unhandled status"
                        );
            return;
    };


    // ////////////////////////
    // Send request to clear cart accounts
    // ////////////////////////
    $scope.clearPaymentCart = function () {
        if ( $rootScope.config.urls.clearCart == null ) {
            $log.debug("Mail Process Controller: Unable to clear cart of accounts");
            return;
        }

        $log.debug("Mail Process Controller: Submitting to clear cart of accounts");
        // We're not overly concerned whether the request succeeds or not, this
        // is just a nice-to-have feature.
        $http({
                method: "POST",
                url: $rootScope.config.urls.clearCart,
                //url: "ws.jsp?service=clearCart",
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).then(function(response) {
                $log.debug("Cart clear response received. Response status: " + (response.status ? response.status : "No status in response"));
                if ( ! response.status ) $log.debug(JSON.stringify(response));
            },function errorCallBack(response) {
                $log.error("Mail Process Controller: Cart clear request returned an error status - ("
                                + response.status + ")");
                $log.error("Mail Process Controller: Response ignored, no action to be taken");
                $log.debug(JSON.stringify(response.data));
                return;
            });
    };

    // User interaction methods
    $scope.newSearch          = function() { window.location.href = $scope.accountSearchUrl; }
}]);
