
app.controller("ErrorController",['$scope','$http','$sce','$log','$exceptionHandler','$rootScope','$injector','$location',
			'paymentFactory','errorManager',
			function($scope,$http,$sce,$log,$exceptionHandler,$rootScope,$injector,$location,paymentFactory,errorManager) {

	$log.debug("Error Controller: Loaded");

    $scope.clientRoot       = $rootScope.config.clientRoot;
    $scope.accountSearchUrl = $rootScope.config.accountSearchUrl;

	$scope.error = errorManager.error;


	// User interaction methods
	$scope.newSearch          = function() { window.location.href = $scope.accountSearchUrl; }


	// ////////////////////////////////////////////////////////////////
	// The following will display HTML from variables in the page
	// Define the following method in the controller:
	// 		$scope.renderHtml = function(htmlCode) { return $sce.trustAsHtml(htmlCode); };
	// Define the following html (or similar) in the HTML page:
	// 		<p ng-bind-html="renderHtml(error.description)"></p>
	// ////////////////////////////////////////////////////////////////
	$scope.renderHtml = function(htmlCode) { $log.debug("Render"); return $sce.trustAsHtml(htmlCode); };

}]);