app.controller("EntryController",['$scope','$rootScope','$log',
                        '$http','$sce','$location','paymentFactory','errorManager',
    function($scope,$rootScope,$log,$http,$sce,$location,paymentFactory,errorManager) {

    $log.debug("Entry Controller: Loaded");
    delete $rootScope.config.accountSearchUrl;

    $scope.clientRoot       = $rootScope.config.clientRoot;
    $scope.accountSearchUrl = $rootScope.config.accountSearchUrl;

    $scope.payment = paymentFactory.get();
    if ( ! $scope.payment ) {
        $log.error("Entry Controller: Failed to find payment data");
        errorManager.raiseDataError();
        return;
    }
    $scope.payment = $scope.payment.payment || $scope.payment;


    // Verify current payment status. 
    if ( $scope.payment.status != $scope.status.READY ) {
        if ( $scope.payment.status == $scope.status.SUCCESS ) {
            $log.debug("Entry Controller: Payment successful, redirecting");
            $location.path($scope.pages.SUCCESS);
            return;
        }

        if ( $scope.payment.status != $scope.status.VERIFIED && $scope.payment.status != $scope.status.FAILURE ) {
            // No other states should be directed to this page
            $log.error("EntryController: Unexpected status: " + $scope.payment.status);
            errorManager.raiseStateError();
            return;
        }

        $scope.payment.status = $scope.status.READY;
    }

    $log.debug("Entry Controller: Verify user entered payment data");

    $scope.renderHtml = function(htmlCode) { return $sce.trustAsHtml(htmlCode); };
    $scope.update     = function() { if ( ! $scope.$$phase ) $scope.$apply(); }


    $scope.gotoVerifyPayment = function() { 
        $location.path($scope.pages.VERIFY); 
        $rootScope.$apply(); // Needed to trigger path change
    }

    $scope.report = function() {
            var payment = $scope.payment;
                    if ( ! payment || ! payment.accounts ) {
                        $log.debug("PaymentEntryController.report: No accounts found. Payment? " 
                                + (payment) + "  Accounts? " + (payment && payment.accounts) );
                        if ( payment && ! payment.accounts ) $log.debug(JSON.stringify(payment));
                        return;
                    }

                    var list = "";
                    for ( var i=0; i < payment.accounts.length; i++ ) {
                        list += payment.accounts[i].account + ": " + payment.accounts[i].paymentAmount + "\n";
                    }

                    $log.debug("PaymentEntryController.report. Payments:\n" + list );
                };


    // Used for flagging the various payment types
    $scope.partialPayment = function(index) {
        $scope.v$verifyAmount($scope.payment.accounts[index]);
    };
    $scope.fullPayment = function(index) {
        $scope.v$setFullPayment($scope.payment.accounts[index]);
    };
    $scope.lienPayment = function(index) {
        $scope.v$setLienPayment($scope.payment.accounts[index]);
    };


    $scope.paymentYearChange = function(index) {
        $scope.partialPayment(index);
    }

    $scope.verifyAccounts = function() {
        return $scope.v$areAccountsValid($scope.payment.accounts);
    }
    $scope.hasPaymentAccountErrors = function() {
        return ! $scope.verifyAccounts();
    }

    $scope.verifyMethod = function() {
        return $scope.v$verifyMethod($scope.payment.method);
    }
    $scope.hasPaymentMethodErrors = function() {
        return ! $scope.verifyMethod();
    }

    $scope.verifyContact = function() {
        return $scope.v$verifyContact($scope.payment.contact,$scope.payment.options);
    }
    $scope.hasContactErrors = function() {
        return ! $scope.verifyContact();
    }

    // Used only for testing
    $scope.setOwnerAsContact = function() {
        $log.debug("Setting contact/owner information");
        if ( ! $scope.payment.contact ) $scope.payment.contact = {};
        var contact     = $scope.payment.contact;
        var owner       = $scope.payment.accounts[0].owner;
        contact.name    = owner.name;
        contact.street  = owner.address1;
        if ( ! contact.street ) contact.street  = (owner.address2 ? owner.address2 : "No addr available");
        contact.city    = owner.city;
        contact.state   = owner.state;
        contact.zipcode = owner.zipcode;
        contact.phone   = "(800) 555-1212";

        //$scope.payment.options.require.phone = true;
        //$scope.payment.options.require.email = false;

        $log.debug("Setting method information");
        var method      = $scope.payment.method;
        method.type     = "PDS";
        delete method.notice;
        var altMethod   = { type: "PDS", pdsToken: "", pdsKey: "AEAE82F9-5A34-47C3-A61E-1E8EE37BE3AD", pdsImage: "", pdsName: "Property Tax Payment", pdsDescription: "Enter your payment details", pdsButton: "Submit Payment" }
        for ( var field in altMethod ) {
            if ( ! method[field] ) method[field] = altMethod[field];
            $log.debug("	Field: " + field + "    Alt: " + altMethod[field] + "   Method: " + method[field]);
        }
        $log.debug("Contact");
        $log.debug(JSON.stringify($scope.payment.contact));
        $log.debug("Method");
        $log.debug(JSON.stringify($scope.payment.method));

    }
    $log.debug("Entry Controller: Entry form ready for user");
    // For testing only, fills in form fields with default information
    //$scope.setOwnerAsContact();
}]);
