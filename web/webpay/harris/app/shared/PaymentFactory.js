/*
{"status":"ERR","description":"Failed to retrieve data due to a processing error","detail":"java.net.UnknownHostException: chaos"}
*/
app.factory (
    "paymentFactory",
    function( $http, $q, $log, $rootScope, errorManager, $location ) {
        var dataObject;

        // Specifies a default location
        //var requestUrl = "control/getPaymentData.jsp";
        var requestUrl = "http://apollo/act_webdev/_labs/sit.jsp";
        var clientId   = null;
        var rid        = null;

        function setUrl(url) { requestUrl = url; }
        function getUrl() { return requestUrl; }

        function setClient(client) { clientId = client; }
        function getClient() { return clientId; }

        function setRid(id) { rid = id; }
        function getRid() { return rid; }

        // Return public API.
        return({
            load: load,
            get: get,
            getUrl: getUrl,
            getClient: getClient,
            getRid: getRid
        });
        // ---
        // PUBLIC METHODS.
        // ---
        function get() {
            $log.debug("Payment Factory: Get request");
            return dataObject;
        }

        function load(requestUrl, clientId, rid) {
            $log.debug("Payment Factory: Load request");

            try {
                if ( requestUrl == null || requestUrl.length < 1 ) throw "no url";
                if ( clientId   == null || clientId.length < 1 ) throw "no cid";
                if ( rid        == null || rid.length < 1 ) throw "no rid";
            } catch (err) {
                $log.debug("Unable to load payment data: " + err);
                return ( $q.reject( err ) );
            }

            setUrl(requestUrl);
            setClient(clientId);
            setRid(rid);

            var request = $http({
                method: "post",
                url: requestUrl, 
                params: { 
                },
                data: {
                }
            });
            return( request.then( loadSuccess, loadError ) );
        }
//                    rid: rid,
//                    clientId: cid


        // ---
        // PRIVATE METHODS.
        // ---

        function loadError( response ) {
            $log.warn("Payment Factory - Load request error response");
            $log.debug(JSON.stringify(response.data));

            if ( ! angular.isObject(response) ) {
                $log.debug("Payment Factory: Unexpected response received, response is not an object");
                return ( $q.reject( response ) );
            }

            if ( ! angular.isObject(response.data) ) {
                $log.debug("Payment Factory: Unexpected data received, response data is not an object");
                return ( $q.reject( { "status": "ERR", detail: response.status + " - " + response.statustext } ) );
            }

            return( $q.reject( response.data ) );
        }


        function loadSuccess( response ) {
            $log.debug("Payment Factory - Load request success response");
            $log.debug(JSON.stringify(response.data));

            if ( ! angular.isObject(response) || ! angular.isObject(response.data) ) {
                $log.debug("Payment Factory: Unexpected response received, response is not an object");
                return ( $q.reject( response.data ) );
            }

            if ( response.data.status != "OK" ) {
                $log.debug("Payment Factory: Invalid response status: " + response.data.status);
                return( $q.reject( response.data ) );
            }

            dataObject = response.data;

            // Adjust dataObject for the SIT merchants
            if ( dataObject.payment ) {
                adjustData(dataObject.payment);
                $log.debug("Final Data:\n" + JSON.stringify(dataObject.payment));
                if ( ! dataObject.payment.accounts ) {
                    $log.debug("Payment Factory: Missing accounts");
                    if ( dataObject.payment.dealers ) {
                        $log.debug("Payment Factory: data is for SIT - converting");
                        var dealers = dataObject.payment.dealers;
                        dataObject.payment.accounts = [];
                        var pay = dataObject.payment.accounts;
                        for ( var i=0; i < dealers.length; i++ ) {
                            var dealer = dealers[i];
                            var accountBase = {};
                            accountBase.account = dealer.can + " - " + dealer.nameline1;
                            accountBase.owner = {};
                            accountBase = JSON.stringify(accountBase);
                            for ( var j=0; j < dealer.payment.length; j++ ) {
                                var dPay = dealer.payment[j];
                                var account = JSON.parse(accountBase);
                                account.owner.name = dPay.description;
                                account.amountDue = dPay.amountDue;
                                account.minPaymentAmount = dPay.minPayment;
                                account.maxPaymentAmount = dPay.maxPayment;
                                pay[pay.length] = account;
                            }
                        }
                    }
                }
            }

            $rootScope.$emit('paymentAccounts loaded', response.data.payment);

            $log.debug("Payment Factory: Payment loaded");
            return response.data;
        }

        function adjustData(cart) {
            var paymentData = cart;
            paymentData.accounts = [];

            $log.debug("Adjusting payment data");
            $log.debug("\tDealers: " + cart.dealers.length);
            for ( var dealerIdx=0; dealerIdx < cart.dealers.length; dealerIdx++ ) {
                $log.debug("\tDealer: " + cart.dealers[dealerIdx].can + " - " + cart.dealers[dealerIdx].nameline1 
                            + " - Accounts to pay: " + cart.dealers[dealerIdx].payment.length);
                var sourceDealer = cart.dealers[dealerIdx];
                for ( var paymentIdx=0; paymentIdx < sourceDealer.payment.length; paymentIdx++ ) {
                    var sourcePayment = sourceDealer.payment[paymentIdx];
                    $log.debug("\t\t\tAccount " + (paymentData.accounts.length+1) + ": " + sourcePayment.description
                                + " - Report: " + sourcePayment.reportSeq
                                + " - Month: " + sourcePayment.month
                                + " - Year: " + sourcePayment.year
                                + " - Due: " + sourcePayment.amountDue
                                + " - Max: " + sourcePayment.maxPayment
                                + " - Min: " + sourcePayment.minPayment
                                + " - Payment: " + (sourcePayment.paymentAmount ? sourcePayment.paymentAmount : sourcePayment.amountDue)
                                );
                    paymentData.accounts[paymentData.accounts.length] = { "account":          sourceDealer.can,
                                                        "owner":{
                                                                "name":     sourceDealer.nameline1,
                                                                "address1": sourceDealer.nameline2,
                                                                "address2": (sourceDealer.nameline3=="null" ? "" : sourceDealer.nameline3),
                                                                "address3": (sourceDealer.nameline4=="null" ? "" : sourceDealer.nameline4),
                                                                "address4": "",
                                                                "city":     sourceDealer.city,
                                                                "state":    sourceDealer.state,
                                                                "zipcode":  sourceDealer.zipcode,
                                                                "country":  ""
                                                                },
                                                        "description":      sourcePayment.description,
                                                        "report":   sourcePayment.reportSeq,
                                                        "month":            sourcePayment.month,
                                                        "year":             sourcePayment.year,
                                                        
                                                        "amountDue":        sourcePayment.amountDue,
                                                        "maxPaymentAmount": (sourcePayment.maxPayment > 0 ? sourcePayment.maxPayment : 0.00),
                                                        "minPaymentAmount": (sourcePayment.minPayment > 0 ? sourcePayment.minPayment : 0.00),
                                                        "amountLien":       "0",
                                                        "amountPending":    sourcePayment.amountPending,
                                                        "hasScheduled":     false,
                                                        "allowEscrow":      false,
                                                        "paymentType":      "full",
                                                        "paymentAmount":    sourcePayment.amountDue
                                                    };
                }
            }
        }

    }
);
