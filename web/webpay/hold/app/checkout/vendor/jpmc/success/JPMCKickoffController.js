app.controller("JPMCKickoffController",
                ['$scope','$rootScope','$log','$location',
                '$compile','$timeout',
                'paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,
            $compile,$timeout,
            paymentFactory,errorManager) {
	$log.debug("JPMC Kickoff Controller: Loaded");

	$log.debug("JPMC Kickoff Controller: Payment data loading");
	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("JPMC Kickoff Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;
	$log.debug("JPMC Kickoff Controller: Payment data loaded");


    // /////////////////// //
    $scope.config = $rootScope.config;
    $scope.processorParam = $rootScope.config.processor.params;
    // ////////////////// //
    // This is until we have everything converted/configured
    // in the root controller and configuration options
    //$scope.config = {};
    //$scope.config.clientId          = "84000000";
    //$scope.config.isTest            = true;
    //$scope.config.accountSearchUrl  = "index.jsp";

    // ////////////////// //
    // Other test settings
	//$scope.payment.status = $scope.status.SUCCESS;
    //if ( ! $scope.payment.reference )
    //    $scope.payment.reference = { "tid": "12123" };
    //if ( ! $scope.payment.amount )
    //    $scope.payment.amount = { "total": "123.11" };

    // ////////////////// //

	if ( ! $scope.config ) {
		$log.error("JPMC Kickoff Controller: Failed to locate configuration");
		errorManager.raiseDataError();
		return;
	}


	// Verify current payment status
	if ( $scope.payment.status != $scope.status.SUCCESS ) {
		if ( $scope.payment.status == $scope.status.FAILURE ) {
			$log.warn("JPMC Kickoff Controller: Payment rejected, redirecting");
			$location.path($scope.pages.FAILURE);
			return;
		}

		$log.error("JPMC Kickoff Controller: Unexpected status: " + $scope.payment.status);
		errorManager.raiseStateError();
		return;
	}


	$log.debug("JPMC Kickoff Controller: JPMC post form loading");
	$log.debug("Configuration:\n" + JSON.stringify($scope.config));
    


    // /////////////////// //
    // Loading and initializing the form template dynamically 
    // requires three steps that must each complete a $apply/$digest
    // cycle before the next one can be attempted. If we don't allow
    // the $apply/$digest to occur the actual data is not ready for
    // the following step so it fails.
    //
    // 1) Load template and insert into DOM
    // 2) Initialize with angularjs so {{xxxxx}} values are set
    // 3) Verify that the values were correctly set (optional)
    //
    // Timing between steps is set for 500ms and 250ms, this may need
    // to be adjusted. When set to 100ms there were occasional failures
    // due to the form not being loaded in time.
    //
    // Note: The load function is async, it isn't finished when the
    //       call returns. If the called page is delayed or responds
    //       slowly (i.e. JSP page compile) the initialize/verify
    //       steps will fail.
    // /////////////////// //

    // Load: template fragment
    var templateName = "app/checkout/vendor/jpmc/success/JPMC-"
                        + $scope.config.clientId
                        + ".dat?" + Date.now();
    var formElement = $("JPMCForm");
    formElement.load(templateName);
    $log.debug("JPMC Kickoff Controller: Dynamic template loaded");

    // Initialize: angularize the code fragment setting any data values
    $timeout(function() {
            $compile(formElement.contents())($scope);
            $log.debug("JPMC Kickoff Controller: Dynamic template values set");

            // Verify: check values are correct
            $timeout(function() {
                        var tid = $("input[name='billerPayorId']",formElement).val();
                        var amount = $("input[name='amountDue']",formElement).val();
                        var biller = $("input[name='billerId']",formElement).val();
                        var billerGroup = $("input[name='billerGroupId']",formElement).val();
                        try {
                            if ( tid !== $scope.payment.reference.tid 
                                || biller !== $scope.processorParam.biller
                                || billerGroup !== $scope.processorParam.billerGroup 
                                || parseFloat(amount) != $scope.payment.amount.total ) {
                                throw("Expected values were not found");
                            }
                        } catch (err) {
                            $log.debug("JPMC Kickoff Controller: Dynamic template validation failed");
                            $log.error(err);
                            $log.error("TID: " + tid + "   Amount: " + amount + "    BillerGroup: " + billerGroup);
                            errorManager.raiseError(
                                        "System Error Occurred",
                                        "We are unable to complete your payment",
                                        "An error occurred that is preventing us "
                                        + "from completing your payment. "
                                        + "Please try again later",
                                        ""
                                    );
                            return;
                        }
                        $log.debug("JPMC Kickoff Controller: Dynamic template verified");
                    },250);
            },500);

	$log.debug("JPMC Kickoff Controller: Initialization complete");
}]);
