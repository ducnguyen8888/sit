app.controller("VerifyController",
                ['$scope','$rootScope','$log','$location',
                '$filter','$timeout',
                'paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,
            $filter,$timeout,
            paymentFactory,errorManager) {
	$log.debug("Verify Controller: Loaded");

    /*
    var content = '<h2>New content loaded previously</h2>';
    var templateName = $route.current.templateUrl;

    $templateCache.put(templateName, content);
    $route.reload();
    */


	$log.debug("Verify Controller: Payment data loading");
	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("Verify Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;
	$log.debug("Verify Controller: Payment data loaded");


    $scope.application      = $rootScope.application;
    $scope.config = $rootScope.config;
	if ( ! $scope.config ) {
		$log.error("Verify Controller: Failed to locate configuration");
		errorManager.raiseDataError();
		return;
	}

	// Verify current payment status
	$log.debug("Verify Controller: Verify payment status - " + $scope.payment.status);
	if ( $scope.payment.status != $scope.status.READY ) {
		if ( $scope.payment.status == $scope.status.SUCCESS ) {
			$log.debug("Process Controller: Payment successful, redirecting");
			$location.path($scope.pages.SUCCESS);
			return;
		}
		if ( $scope.payment.status == $scope.status.FAILURE ) {
			$log.debug("Process Controller: Payment rejected, redirecting");
			$location.path($scope.pages.FAILURE);
			return;
		}

		if ( $scope.payment.status != $scope.status.VERIFIED ) {
			// No other states should be directed to this page
			$log.error("Process Controller: Unexpected status: " + $scope.payment.status);
			errorManager.raiseStateError();
			return;
		}

		$scope.payment.status = $scope.status.READY;
	}


	// Verify the payment data
	$log.debug("Verify Controller: Verifying payment data");

	for ( var i=0; i < $scope.payment.accounts.length; i++ ) {
		$scope.payment.accounts[i].showOnSummary = ($scope.payment.accounts[i].paymentAmount > 0);

		// If the payment is a lien payment then there is no payment year
		if ( $scope.payment.accounts[i].paymentType == "lien" ) {
			$scope.payment.accounts[i].paymentYear = "";
		}
	}

    // Check for errors
	$scope.accountErrors = ! $scope.v$areAccountsValid($scope.payment.accounts);
	$scope.contactErrors = ! $scope.v$verifyContact($scope.payment.contact,$scope.payment.options);
    $scope.methodErrors  = false;

    // If this is something other than a vendor payment we'll need to 
    // verify the payment method information
    if ( $scope.payment.method.type != "vendor" ) {
        $scope.methodErrors = ! $scope.v$verifyMethod($scope.payment.method);
        if ( $scope.payment.method.type == "cc" ) {
            if ( $scope.payment.method.cardNumber && $scope.payment.method.cardNumber.length > 0 )
                $scope.payment.method.cardType = $scope.getCardType($scope.payment.method.cardNumber);
            else
                $scope.payment.method.cardType = "";
        }
    }

    // Was there an error in the data entry?
    if ( $scope.accountErrors || $scope.methodErrors || $scope.contactErrors ) {
		$log.debug("Verify Controller: Found data/amount errors, redirecting");
		$scope.payment.options.enableAll = true;
		$location.path($scope.pages.ENTRY);
		return;
	}

	$log.debug("Verify Controller: No user entry errors found");

	$scope.payment.amount = $scope.v$paymentTotals($scope.payment.accounts);
	$scope.rpad = function(val,size) { return ("             " + val).slice(-size); }
	$log.debug("Verify Controller: Payment totals: "
				+ $scope.rpad($filter("currency")($scope.payment.amount.tax),11)
				+ $scope.rpad($filter("currency")($scope.payment.amount.fee),9)
				+ $scope.rpad($filter("currency")($scope.payment.amount.total),12)
				);
	if ( $scope.payment.amount.tax == 0 || $scope.payment.amount.total == 0 ) {
		$log.debug("Verify Controller: No payment amount specified, redirecting");
		$scope.payment.options.enableAll = true;
		$location.path($scope.pages.ENTRY);
		alert("You must specify a payment amount");
		return;
	}


    $scope.vendor = $rootScope.config.processor.name;
    $scope.rates = $rootScope.config.processor.rates;

    $log.warn("--->Payment Method:");
    $log.warn(JSON.stringify($scope.payment.method));

    $scope.vendor = $scope.payment.method.displayName;
    $scope.rates = $scope.payment.method.rates;
    $scope.payment.fees = [];
    $scope.payment.estimatedMaxAmount = 0.0;
    $scope.payment.estimatedMinAmount = 0.0;
    if ( $scope.rates ) {
        //"echeck":     { "amount": "1.50",  "minimum": "1.50" },
        //"creditcard": { "rate":   "0.025", "minimum": "0.0" },

        var estimates = $scope.payment.fees;
        for ( var i=0; i < $scope.rates.length; i++ ) {
            var rate = $scope.rates[i];
            estimates[i] = { name: rate.name, 
                            rate: rate.rate,
                            amount: rate.amount,
                            minimum: rate.minimum,
                            maximum: rate.maximum,
                            note: rate.note,
                            fee: 0.0
                            };
            if ( rate.amount )
                estimates[i].fee = rate.amount;
            else
                estimates[i].fee = parseInt(rate.rate * $scope.payment.amount.total * 100 + 0.9)/100;

            // Ensure that we don't go below the minimum fee amount
            if ( rate.minimum && rate.minimum > estimates[i].fee )
                estimates[i].fee = rate.minimum;
            // Ensure that we don't exceed the maximum fee amount
            if ( rate.maximum && rate.maximum < estimates[i].fee )
                estimates[i].fee = rate.maximum;

            estimates[i].totalPaymentAmount = parseFloat($scope.payment.amount.total) + parseFloat(estimates[i].fee);

            // Track the maximum expected payment amount
            if ( $scope.payment.estimatedMaxAmount < estimates[i].totalPaymentAmount )
            {
                $scope.payment.estimatedMaxAmount = estimates[i].totalPaymentAmount;
            }
            // Track the minimum expected payment amount
            if ( i == 0 || $scope.payment.estimatedMinAmount > estimates[i].totalPaymentAmount )
            {
                $scope.payment.estimatedMinAmount = estimates[i].totalPaymentAmount;
            }
            $log.debug("Fee: " + JSON.stringify(estimates[i]));
        }
    }


	// We'll want to have redirected back to the entry page before this point
	// if we've discovered an error. Otherwise we'll flag that this payment is
	// ready to be processed.
	$scope.payment.status = $scope.status.VERIFIED;


	$log.debug("Verify Controller: Payment data validated");


	// User interaction methods
	$scope.newSearch          = function() { window.location.href = $scope.config.accountSearchUrl; }
	$scope.reenterInformation = function() { $location.path($scope.pages.ENTRY); }
	$scope.processPayment     = function() {
        $rootScope.paymentProcessingStart = Date.now();
        $location.path($scope.pages.PROCESS); 
    }
	//$scope.processPayment     = function() { $location.path($scope.pages.SUCCESS); }
    $scope.clearPaymentWarning = function()
    {
        clearPaymentWarning();
    }
}]);
