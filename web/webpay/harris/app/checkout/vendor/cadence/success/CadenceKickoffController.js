app.controller("CadenceKickoffController",
                ['$scope','$rootScope','$log','$location',
                '$compile','$timeout','$sce',
                'paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,
            $compile,$timeout,$sce,
            paymentFactory,errorManager) {
	$log.debug("Cadence Kickoff Controller: Loaded");

	$log.debug("Cadence Kickoff Controller: Payment data loading");
	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("Cadence Kickoff Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;
	$log.debug("Cadence Kickoff Controller: Payment data loaded");

    $scope.payment.reference.account = $scope.payment.accounts[0].account + "-" + $scope.payment.contact.name;


    // /////////////////// //
    $scope.config = $rootScope.config;
    $scope.processorParam = $rootScope.config.processor.params;
    $scope.processorParam.url = $sce.trustAsResourceUrl($scope.processorParam.url);

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
		$log.error("Cadence Kickoff Controller: Failed to locate configuration");
		errorManager.raiseDataError();
		return;
	}


	// Verify current payment status
	if ( $scope.payment.status != $scope.status.SUCCESS ) {
		if ( $scope.payment.status == $scope.status.FAILURE ) {
			$log.warn("Cadence Kickoff Controller: Payment rejected, redirecting");
			$location.path($scope.pages.FAILURE);
			return;
		}

		$log.error("Cadence Kickoff Controller: Unexpected status: " + $scope.payment.status);
		errorManager.raiseStateError();
		return;
	}

	$log.debug("Cadence Kickoff Controller: Initialization complete");
}]);
