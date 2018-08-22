/* Controller to handle loading and validation of the server data.
 */
app.controller("LoadController",
    [ "$scope", "$rootScope", "$log", "$location", "$filter", "paymentFactory", "errorManager", "$timeout",
    function($scope,$rootScope,$log,$location,$filter,paymentFactory,errorManager,$timeout) {
        $log.debug("Load Controller: Loading payment data");

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


        paymentFactory.load($rootScope.config.urls.getPaymentData, $rootScope.config.clientId, $rootScope.rid)
                    .then( function(response) { $scope.loadSuccess(response); },
                          function(response) { $scope.loadError(response); }
                          );

        $scope.loadError = function(response) { // HTTP Errors
            $log.debug("Load Controller: Load error response received");
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
            $log.debug("Load Controller: Load success response received");
            $timeout.cancel($scope.timeoutPromise);

            // We have a valid response, now make sure that it's valid for payments

            if ( ! angular.isObject(response.payment) || ! angular.isObject(response.payment.accounts) ) {
                $log.warn("Load Controller: Invalid payment data, no payment/accounts");
                errorManager.raiseError(
                    (response.title       || "Server Data Error"),
                    (response.summary     || "Payment data was not returned as expected"),
                    (response.description || "This error may be temporary, please try again in a few minutes. "
                                        + "If the problem continues please contact the tax office"),
                    (response.detail      || "Payment data did not include the expected data")
                    );
                return;
            }

            // Make sure there's at least one account specified, otherwise the user's session may have timed out
            if ( response.payment.accounts.length == 0 ) {
                $log.warn("Load Controller: No payment accounts were found. Possible user session timeout.");
                errorManager.raiseError(
                        (response.title       || "No Accounts Found"),
                        (response.summary     || "We did not find any accounts to pay"),
                        (response.description || "No accounts to pay were found, this may be due to your "
                                            + "browser session timing out. Please try again"),
                        (response.detail)
                    );
                return;
            }


            $log.debug("Load Controller: Adjusting payment data to make sure it's ready for use");

            // Make sure we have the data fields we need for the user forms, these
            // will likely not have been provided by the server.

            var payment = response.payment;

            if( ! payment.contact ) payment.contact = {};
            if( ! payment.method  ) payment.method  = { "type": "CC" };

            // Adjust account data here.
            payment.isTest = $rootScope.config.isTest;

            // Flag to let us know that we shouldn't run the data validation routines yet.
            payment.newdata = true;

            // Adjust and normalize our data
            for ( var i=0; i < payment.accounts.length; i++ ) {
                var account = payment.accounts[i];

                // Set owner address we want to display
                var owner   = account.owner;
                account.ownerAddress = $scope.formatAddress(owner.name, 
                                            owner.address1, owner.address2, owner.address3, 
                                            owner.city, owner.state, owner.zipcode);

                // Make sure our amounts are valid
                account.amountDue     = (account.amountDue  ? parseFloat(account.amountDue.replace(/[^0-9._-]/g, '')) : 0);
                account.amountLien    = (account.amountLien ? parseFloat(account.amountLien.replace(/[^0-9._-]/g, '')) : 0);
                account.amountPending = (account.amountPending ? parseFloat(account.amountPending.replace(/[^0-9._-]/g, '')) : 0);
                account.paymentAmount = (account.paymentAmount ? parseFloat(account.paymentAmount.replace(/[^0-9._-]/g, '')) : 0);

                if ( ! account.paymentType ) account.paymentType = "full";
                if ( account.paymentAmount < 0 ) account.paymentAmount = 0;

                if ( ! account.paymentYear ) account.paymentYear = "";


                // Escrow payments are allowed if the user doesn't owe anything or they only owe a Lien
                // We'll assume this is an escrow payment if the user doesn't owe anything
                if ( account.paymentType != "fixed" && account.allowEscrow && account.amountDue == 0 ) {
                    account.yearsDue = [ {"year":"Escrow"} ];
                    account.paymentYear = "Escrow";
                    account.paymentType = "escrow";
                }

                // Payment types are fixed, escrow, lien, full, and partial
                if ( account.paymentType == "fixed" ) {
                    // We're assuming that there's a reason that the payment is fixed, we're not second guessing the amount
                } else if ( account.paymentType == "escrow" ) {
                    // We don't care how much escrow payments are for
                } else if ( account.paymentType == "lien" ) {
                    if ( account.paymentAmount != account.lienAmount ) account.paymentAmount = account.amountLien;
                } else if ( account.paymentType == "full" || account.paymentAmount >= account.amountDue ) {
                    if ( ! account.paymentType == "full" ) account.paymentType = "full";
                    if ( account.paymentAmount != account.amountDue ) account.paymentAmount = account.amountDue;
                } else {
                    if ( ! account.paymentType == "partial" ) account.paymentType = "partial";
                }
            }
            $scope.report(payment);

            $log.debug("Load Controller: Data ready for user, redirecting to " + $scope.pages.ENTRY);
            $location.path($scope.pages.ENTRY);
            return;
        }

        $scope.report = function(payment) {
            var list = "";
            for ( var i=0; i < payment.accounts.length; i++ ) {
                list += $scope.pad(payment.accounts[i].account,16) + ": "
                    + $scope.rpad($filter("currency")(payment.accounts[i].amountDue),12)
                    + $scope.rpad($filter("currency")(payment.accounts[i].paymentAmount),12)
                    + "   " + $scope.pad((payment.accounts[i].paymentYear ? payment.accounts[i].paymentYear : ""),10)
                    + "   " + payment.accounts[i].paymentType
                    + "\n";
            }

            $log.debug("Payments:\n" + list );
        }

        $scope.pad = function(val, size) {
            return (val + "                ").substring(0,size);
        }
        $scope.rpad = function(val, size) {
            return ("                "+val).slice(-size);
        }


        $scope.formatAddress = function(name, address1, address2, address3, city, state, zipcode) {
                    var address = "";
                    if ( name ) address += name + "<br>";
                    if ( address1 ) address += address1 + "<br>\n";
                    if ( address2 ) address += address2 + "<br>\n";
                    if ( address3 ) address += address3 + "<br>\n";

                    if ( city ) address += city;
                    if ( state ) address += (city ? ", " : "") + state;
                    if ( zipcode ) address += (city || state ? "  " : "") 
                        + (zipcode.length == 9 ? zipcode.substring(0,5) + "-" + zipcode.substring(5) : zipcode);

                    return address;
                };

    }]);