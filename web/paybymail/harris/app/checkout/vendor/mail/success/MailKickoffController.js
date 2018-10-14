app.controller("MailKickoffController",
                ['$scope','$rootScope','$log','$location',
                '$compile','$timeout','$sce',
                'paymentFactory','errorManager',
	function($scope,$rootScope,$log,$location,
            $compile,$timeout,$sce,
            paymentFactory,errorManager) {
	$log.debug("Mail Kickoff Controller: Loaded");

	$log.debug("Mail Kickoff Controller: Payment data loading");
    $scope.application = $rootScope.application;

	$scope.payment = paymentFactory.get();
	if ( ! $scope.payment ) {
		$log.error("Mail Kickoff Controller: Failed to find payment data");
		errorManager.raiseDataError();
		return;
	}
	$scope.payment = $scope.payment.payment || $scope.payment;
	$log.debug("Mail Kickoff Controller: Payment data loaded");

    $scope.payment.reference.account = $scope.payment.accounts[0].account + "-" + $scope.payment.contact.name;



	// Verify current payment status
	if ( $scope.payment.status != $scope.status.SUCCESS ) {
		if ( $scope.payment.status == $scope.status.FAILURE ) {
			$log.warn("Mail Kickoff Controller: Payment rejected, redirecting");
			$location.path($scope.pages.FAILURE);
			return;
		}

		$log.error("Mail Kickoff Controller: Unexpected status: " + $scope.payment.status);
		errorManager.raiseStateError();
		return;
	}

	$log.debug("Mail Kickoff Controller: Initialization complete");
}]);
