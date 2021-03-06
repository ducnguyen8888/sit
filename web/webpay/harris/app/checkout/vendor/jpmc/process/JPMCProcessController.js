app.controller("JPMCProcessController",
                ['$scope','$rootScope','$log','$location',
                '$timeout','$http',
                'paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,
            $timeout,$http,
            paymentFactory,errorManager) {
	$log.debug("JPMC Process Controller: Loaded");




	$log.debug("JPMC Process Controller: Payment data loading");
	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("JPMC Process Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;
	$log.debug("JPMC Process Controller: Payment data loaded");


    $scope.config = $rootScope.config;
	if ( ! $scope.config ) {
		$log.error("JPMC Process Controller: Failed to locate configuration");
		errorManager.raiseDataError();
		return;
	}


    // Verify current payment status. 
    if ( $scope.payment.status != $scope.status.VERIFIED ) {
        if ( $scope.payment.status == $scope.status.SUCCESS ) {
            $log.debug("JPMC Process Controller: Payment successful, redirecting");
            $location.path($scope.pages.SUCCESS);
            return;
        }
        if ( $scope.payment.status == $scope.status.FAILURE ) {
            $log.debug("JPMC Process Controller: Payment rejected, redirecting");
            $location.path($scope.pages.FAILURE);
            return;
        }

        // No other states should be directed to this page
        $log.error("JPMC Process Controller: Unexpected status: " + $scope.payment.status);
        errorManager.raiseStateError();
        return;
    }
    $scope.payment.status = $scope.status.PROCESSING;
    $log.debug("JPMC Process Controller: Processing payment");


    // Since the payment has been verified by the user we're not going
    // to bother checking for any outstanding errors. That's the job the Verify page.

    $scope.paymentParameters = null;
    $scope.setPaymentParameters = function () {
        $log.debug("JPMC Process Controller: Setting payment parameters");
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

        $log.debug("JPMC Process Controller: Process time limit exceeded, checking status");
        if ( payment.status == status.PROCESSING ) {
            $log.debug("JPMC Process Controller: Process time limit exceeded, payment is still processing. Redirecting to " + pages.ERROR);
            errorManager.raiseError("Processor Payment Error",
                        "Unable to Record your Payment Information",
                        "It is taking longer than expected to record your payment "
                        + "information. "
                        + "This delay may be due to unusually high payment volume. "
                        + "Please try again later.",
                        ""
                    );
            return;
        }
        $log.debug("JPMC Process Controller: Process time limit exceeded, payment status is not processing " + payment.status + ". It's not processing so we're abandoning this check");
    }

    // ////////////////////////
    // Save payment information
    // ////////////////////////
    $scope.savePaymentInformation = function () {
        $log.debug("JPMC Process Controller: Recording payment information");

        $scope.paymentParameters = $scope.paymentParameters; 
        $log.debug(JSON.stringify($scope.paymentParameters));
        $scope.processingStatus = "Recording your payment information...";

        $scope.payment.reference = {};

        $http({
            method: "POST",
            url: $rootScope.config.urls.vendorPayment.JPMC,
            data: $scope.paymentParameters,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}

            }).then(function(response) {
                $log.debug("Payment save response received. Response status: " + (response.status ? response.status : "No status in response"));
                if ( ! response.status ) $log.debug(JSON.stringify(response));
                $scope.processorFinished(response);
            },function errorCallBack(response) {
                $log.error("JPMC Process Controller: Server returned an error status - ("
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
            $log.debug("JPMC Process Controller: Analyzing payment processing response");
            $log.debug("Response: " + JSON.stringify(response.data));

            $timeout.cancel($scope.timeoutPromise);
            $scope.payment.response = response.data;
            $scope.payment.reference.auth = (response.data.reference ? response.data.reference.auth : "");
            $scope.payment.reference.type = (response.data.reference ? response.data.reference.type : "");
            $scope.payment.reference.detail = (response.data.reference ? response.data.reference.detail : "");
            $scope.payment.reference.datetime = (response.data.reference ? response.data.reference.datetime : "");
            $scope.payment.reference.tid = (response.data.reference ? response.data.reference.tid : "");

            $log.debug("JPMC Process Controller: TID " + $scope.payment.reference.tid);


            // Check processing status
            $log.debug("JPMC Process Controller: Verifying processing response status");
            if ( ! response.data.status || response.data.status != "OK" ) {
                $log.debug("JPMC Process Controller: Processing error response. Processing status not 'OK' as expected: " + response.data.status);
                $scope.payment.status = $scope.status.FAILURE;

                $scope.processingStatus = "Processor failure, payment rejected";
                $scope.payment.reference.detail = "Processing response status error. Status: " + response.data.status;
                errorManager.raiseError("Payment Failure",
                            "Your payment was not successful",
                            (response.data.description
                                            ? response.data.description
                                            : "Your payment did not complete due to a processing error, please try again later"
                                            ),
                            (response.data.detail 
                                            ? response.data.detail
                                            : "Processing results indicated an error status or server error"
                                            )
                        );
                return;
            }

            // Verify that we response is formatted the way we expect
            $log.debug("JPMC Process Controller: Verifying processing response format");
            if ( ! response.data.reference ) {
                $log.debug("JPMC Process Controller: Invalid response, no 'reference' found in response");
                $scope.payment.status = $scope.status.FAILURE;

                $scope.processingStatus = "Processor failure, payment rejected";
                $scope.payment.reference.detail = "Processing response was invalid, no reference field found";
                errorManager.raiseError("Payment Failure",
                            "Your payment was not successful",
                            (response.data.description
                                            ? response.data.description
                                            : "Your payment did not complete due to a processing error, please try again later"
                                            ),
                            (response.data.detail 
                                            ? response.data.detail
                                            : "Processing results indicated a missing field or server error"
                                            )
                        );
                return;
            }


            // Check payment status
            $log.debug("JPMC Process Controller: Verifying payment status");
            if ( response.data.reference.status == "success" ) {
                $log.debug("JPMC Process Controller: Payment was successful, reference: " + response.data.reference.ref);

                $scope.payment.status = $scope.status.SUCCESS;
                $scope.payment.reference.auth = (response.data.reference.auth 
                                                                ? response.data.reference.auth 
                                                                : $scope.payment.reference.tid
                                                                );
                $scope.payment.reference.detail = (response.data.reference.detail
                                                                ? response.data.reference.detail 
                                                                : "Payment was successfully charged"
                                                                );

                $location.path($scope.pages.SUCCESS);

                // Attempt to clear the cart of any payments
                $scope.clearPaymentCart();
                return;
            }

            // $scope.payment.reference
            $log.debug("JPMC Process Controller: Payment was NOT successful, status: " + response.data.reference.status);
            $scope.payment.status = $scope.status.FAILURE;
            $scope.payment.reference.auth = (response.data.reference.auth 
                                                            ? response.data.reference.auth 
                                                            : $scope.payment.reference.tid
                                                            );
            $scope.payment.reference.detail = (response.data.reference.detail
                                                            ? response.data.reference.detail 
                                                            : "Payment failed"
                                                            );

            // Verify that our payment status is expected, otherwise we have an error
            if ( response.data.reference.status == "failure" ) {
                $log.debug("JPMC Process Controller: Payment failed, reference: " + response.data.reference);
                $location.path($scope.pages.FAILURE);
                return;
            }

            // We have a systemic error, the response received is not one we've programmed to handle
            $log.debug("JPMC Process Controller: Unknown payment status: " + response.data.reference.status);
            errorManager.raiseError("Payment Status Failure",
                        "Failed to Identify Payment Status",
                        "The status returned for your payment is unknown"
                    );
            return;
    };


    // ////////////////////////
    // Send request to clear cart accounts
    // ////////////////////////
    $scope.clearPaymentCart = function () {
        if ( $rootScope.config.urls.clearCart == null ) {
            $log.debug("JPMC Process Controller: Unable to clear cart of accounts");
            return;
        }

        $log.debug("JPMC Process Controller: Submitting to clear cart of accounts");
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
                $log.error("JPMC Process Controller: Cart clear request returned an error status - ("
                                + response.status + ")");
                $log.error("JPMC Process Controller: Response ignored, no action to be taken");
                $log.debug(JSON.stringify(response.data));
                return;
            });
    };

    // User interaction methods
    $scope.newSearch          = function() { window.location.href = $scope.accountSearchUrl; }
}]);
