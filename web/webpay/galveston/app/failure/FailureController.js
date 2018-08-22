app.controller("FailureController",
                ['$scope','$rootScope','$log','$location',
                'paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,
            paymentFactory,errorManager) {
	$log.debug("Failure Controller: Loaded");


	$log.debug("Failure Controller: Payment data loading");
	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("Failure Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;
	$log.debug("Failure Controller: Payment data loaded");


    $scope.config = $rootScope.config;
	if ( ! $scope.config ) {
		$log.error("Failure Controller: Failed to locate configuration");
		errorManager.raiseDataError();
		return;
	}


	// Verify current payment status. 
	if ( $scope.payment.status != $scope.status.FAILURE ) {
		if ( $scope.payment.status == $scope.status.SUCCESS ) {
			$log.debug("Failure Controller: Payment successful, redirecting");
			$location.path($scope.pages.SUCCESS);
			return;
		}

		// No other states should be directed to this page
		$log.error("Failure Controller: Unexpected status: " + $scope.payment.status);
		errorManager.raiseStateError();
		return;
	}
	$log.debug("Failure Controller: Initialization complete");


	// User interaction methods
	$scope.reenterInformation = function() { $location.path($scope.pages.ENTRY); }
	$scope.newSearch          = function() { window.location.href = $scope.config.accountSearchUrl; }
}]);
