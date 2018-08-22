app.controller("SuccessController",['$scope','$rootScope','$log','$location','paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,paymentFactory,errorManager) {

	$log.debug("Success Controller: Loaded, Loaded");

    $scope.clientRoot       = $rootScope.config.clientRoot;
    $scope.accountSearchUrl = $rootScope.config.accountSearchUrl;


	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("Success Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;


	// Verify current payment status. 
	if ( $scope.payment.status != $scope.status.SUCCESS ) {
		if ( $scope.payment.status == $scope.status.FAILURE ) {
			$log.debug("Success Controller: Payment rejected, redirecting");
			$location.path($scope.pages.FAILURE);
			return;
		}

		$log.error("Success Controller: Unexpected status: " + $scope.payment.status);
		errorManager.raiseStateError();
		return;
	}
	$log.debug("Success Controller: Initialization complete");


	// User interaction methods
	$scope.newSearch          = function() { window.location.href = $scope.accountSearchUrl; }
}]);
