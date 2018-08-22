/* Controller to handle loading and validation of the configuration data.
 */
app.controller("ConfigController",
	[ "$scope", "$rootScope", "$log", "$location", "$filter", "configFactory", "errorManager", "$timeout",
	function($scope,$rootScope,$log,$location,$filter,configFactory,errorManager, $timeout) {
		$log.debug("Config Controller: Loading payment data");

        // Probably isn't defined yet, but just in case
		$scope.clientRoot       = $rootScope.config.clientRoot;
		$scope.accountSearchUrl = $rootScope.config.accountSearchUrl;


        // ////////////////////////
        // Set maximum processing time limit so the user isn't left in limbo
        // ////////////////////////

        // This is used to set a maximum limit to how long we'll make the user wait and guess what's going on.
        // If the request returns before we time out we'll cancel the timer.
        $scope.timeoutPromise = $timeout(function() { $scope.transactionWaitLimit($scope.payment,$scope.pages,$scope.status); },15000);
        $scope.transactionWaitLimit = function(payment,pages,status) {
            $log.debug("Config Controller: Process time limit exceeded, redirecting to " + pages.ERROR);
            errorManager.raiseError("System Error",
                        "Failed to retrieve Payment Information",
                        "The system is taking longer than expected. This delay may be due to unusually high activity. Please check back later.",
                        ""
                    );
            return;
        }

        configFactory.load($rootScope.rid)
					.then( function(response) { $scope.loadSuccess(response); },
						  function(response) { $scope.loadError(response); }
						  );

		$scope.loadError = function(response) { // HTTP Errors
			$log.debug("Config Controller: Load error response received");
            $timeout.cancel($scope.timeoutPromise);
			$log.debug(JSON.stringify(response));

			errorManager.raiseError(
						"Failed to Load Payment Data",
						"An error occurred while retrieving the payment information",
						response.description,
						response.detail);
			return;
			};

		$scope.loadSuccess = function(response) {
			$log.debug("Config Controller: Load success response received");
            $timeout.cancel($scope.timeoutPromise);

			// We have a valid response, now make sure that it's valid for payments

			if ( ! angular.isObject(response.config) || ! angular.isObject(response.config.urls) ) {
				$log.warn("Config Controller: Invalid config data, no configuration");
				errorManager.raiseError(
					(response.title       || "Server Data Error"),
					(response.summary     || "Payment data was not returned as expected"),
					(response.description || "This error may be temporary, please try again in a few minutes. "
										+ "If the problem continues please contact the tax office"),
					(response.detail      || "Payment data did not include the expected data")
					);
				return;
			}

			// Make sure there's at least one url specified, otherwise the user's session may have timed out
			if ( response.config.urls.length == 0 ) {
				$log.warn("Config Controller: No config paths were found. Possible user session timeout.");
				errorManager.raiseError(
						(response.title       || "No Accounts Found"),
						(response.summary     || "We did not find any accounts to pay"),
						(response.description || "No accounts to pay were found, this may be due to your "
											+ "browser session timing out. Please try again"),
						(response.detail)
					);
				return;
			}

			$log.debug("Config Controller: Adjusting config data to make sure it's ready for use");

			// Make sure we have the data fields we need for the user forms, these
			// will likely not have been provided by the server.

			var config = response.config;

			$scope.report(config);

			$log.debug("Config Controller: Configuration loaded, redirecting to " + $scope.pages.LOADDATA);
			$location.path($scope.pages.LOADDATA);
			return;
		}

		$scope.report = function(config) {
			$log.debug("config:\n" + JSON.stringify(config) );
		}

	}]);