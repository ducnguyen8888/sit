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

	$log.debug("JPMC Kickoff Controller: Initialization complete");
}]);
