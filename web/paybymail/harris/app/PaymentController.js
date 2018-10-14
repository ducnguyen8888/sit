
app.controller("PaymentController",['$scope','$rootScope','$log','$sce','$exceptionHandler','$injector','$location','$filter','configFactory','paymentFactory','errorManager',
	function($scope,$rootScope,$log,$sce,$exceptionHandler,$injector,$location,$filter,configFactory,paymentFactory,errorManager) {

	$log.debug("Payment Controller: loaded");

	$scope.status = $rootScope.status;
	$scope.pages  = $rootScope.pages;

    // We don't want to go any further if
    // stop application has been flagged
	if ( $rootScope.stopApplication ) return;



	$scope.v$paymentTotals = function(accounts) {
		if ( ! accounts ) return false;

		$log.debug("v$paymentTotals: verify payment amounts");
		var amount = { tax: 0, fee: 0, total: 0 };
		for ( var i=0; i < accounts.length; i++ ) {
			if ( ! accounts[i].paymentAmount ) accounts[i].paymentAmount = 0;
			accounts[i].paymentAmount = parseFloat(accounts[i].paymentAmount);

			// Makes no sense but we have to use Math.round instead of
			// Math.floor to get the amount to come out correctly.
			// For 33.12 Math.round returns 33.12 but Math.floor returns 33.11.
			amount.tax += Math.round(accounts[i].paymentAmount*100);
		}
		amount.total = amount.tax + amount.fee;

		amount.tax = amount.tax / 100;
		amount.fee = amount.fee / 100;
		amount.total = amount.total / 100;

		$log.debug("v$paymentTotals: " + JSON.stringify(amount));

		return amount;
	}

	$scope.v$isFullPayment = function(account) {
		return account
					&& account.paymentType == "full" 
					&& account.paymentAmount == account.amountDue;
	}
	$scope.v$setFullPayment = function(account) {
		if ( account ) {
			account.paymentType = "full";
			account.paymentAmount = account.amountDue;
		}
	}
	$scope.v$isLienPayment = function(account) {
		return account
					&& account.paymentType == "lien" 
					&& account.paymentAmount == account.amountLien;
	}
	$scope.v$setLienPayment = function(account) {
		if ( account ) {
			account.paymentType   = "lien";
			account.paymentAmount = account.amountLien;
			account.paymentYear   = "";
		}
	}
	$scope.v$isFixedPayment = function(account) {
		return account && account.paymentType == "fixed";
	}
	$scope.v$isEscrowPayment = function(account) {
		return account
					&& (account.paymentType == "escrow" 
						|| account.paymentYear == "Escrow");
	}
	$scope.v$verifyAmount = function(account) {
		if ( ! account ) return false;

		// Clear any prior errors
		account.error = "";

        // We want to allow the user to exclude this account
        // from the payment. If the user clears out the payment
        // amount entirely we'll assume they are excluding this
        // account from the payment.
        if ( account.paymentAmount === "" ) {
            account.error = "A blank or $0.00 payment amount excludes this account from your payment";
            account.paymentType = "partial";
            return true;
        }

        // Verify that the amount is a valid value
        var amountValue = parseFloat(account.paymentAmount);
        if ( isNaN(amountValue) ) {
            account.error = "Invalid amount specified. "
                            + "Please enter a valid payment amount.";
            return false;
        }

        // If the user specifies $0.00 we'll assume they are
        // excluding this account, so we'll allow it.
        if ( amountValue === 0 ) {
            account.error = "A blank or $0.00 payment amount excludes this account from your payment";
            account.paymentType = "partial";
            return true;
        }

        // If this is a fixed, full, lien we know the amount is valid.
        // If this is an escrow payment we'll allow any amount to be
        // paid.
		if ( $scope.v$isFullPayment(account) 
			|| $scope.v$isLienPayment(account) 
			|| $scope.v$isFixedPayment(account) 
			|| account.paymentType == "escrow" ) return true;

        // Check to see if the amount to pay is the full amount
        // but the partial payment option is selected
        if ( account.paymentAmount == account.amountDue ) {
            $scope.v$setFullPayment(account);
            return true;
        }


		// If payment type is not full, lien, or escrow it is, by default, a partial payment
		if ( account.paymentType != "partial" ) account.paymentType = "partial";

		// If this is an escrow payment we don't care what the amount is.
        // Escrow payments are defined by either the payment type or by
        // specifying the tax year as escrow.
		if ( $scope.v$isEscrowPayment(account) ) return true;

        // Verify that we're paying the minimum required
        if ( account.paymentAmount <= account.amountDue ) {
            var minAmount = parseFloat(account.minPaymentAmount) || 0;
            if ( minAmount == 0
                || account.paymentAmount >= minAmount )
                return true;

            account.error = "The minimum payment is "
                            + $filter('currency')(account.minPaymentAmount)
                            + ". Please enter at least this amount.";
            return false;
        }

        // Verify that we don't exceed the maximum required
        if ( account.paymentAmount > account.amountDue ) {
            if ( ! account.maxPaymentAmount 
                || account.maxPaymentAmount == 0
                || account.paymentAmount <= account.maxPaymentAmount )
                return true;

            account.error = "You may not pay more than "
                            + $filter('currency')(account.maxPaymentAmount)
                            + ". Please enter a different amount.";
            return false;
        }

		return true;
	};

	$scope.v$areAccountsValid = function(accounts) {
		if ( ! accounts ) return false;

		$log.debug("v$areAccountsValid: verify payment amounts");
		var isValid = true;

		if ( Array.isArray(accounts) ) {
			for ( var i=0; i < accounts.length; i++ ) {
				if ( ! accounts[i].paymentAmount ) accounts[i].paymentAmount = 0;
				accounts[i].paymentAmount = parseFloat(accounts[i].paymentAmount);
				isValid = isValid && $scope.v$verifyAmount(accounts[i]);
				var p = accounts[i];
				$log.debug(p.account 
							+ "  Type: "   + p.paymentType 
							+ "  Due: "    + p.amountDue 
							+ "  Amount: " + p.paymentAmount 
							+ "  Year: "   + p.paymentYear 
							+ "  Valid? "  + isValid);
			}

			var amounts = $scope.v$paymentTotals(accounts);
			$log.debug(amounts);
			isValid = isValid && amounts.tax > 0;
			if ( amounts.tax == 0 ) accounts[0].error = "At least one account must be paid";
		} else {
			if ( ! accounts.paymentAmount ) accounts.paymentAmount = 0;
			accounts.paymentAmount = parseFloat(accounts.paymentAmount);
			isValid = $scope.v$verifyAmount(accounts);
			$log.debug(paymentaccount 
							+ "  Type: "   + accounts.paymentType 
							+ "  Due: "    + accounts.amountDue 
							+ "  Amount: " + accounts.paymentAmount 
							+ "  Year: "   + accounts.paymentYear 
							+ "  Valid? "  + isValid);
		}

		$log.debug("v$areAccountsValid: payment amounts are " + (isValid ? "valid" : "invalid"));
		return isValid;
	}


	$scope.v$verifyMethod = function(method) {
		if ( ! method ) return false;

		$log.debug("v$verifyMethod: verify payment method");
		method.errors = {};
		var errors  = method.errors;

		if ( ! method.cardNumber ) {
			errors.cardNumber = "Credit card number must be specified";
		} else if ( ! $scope.v$isCCValid(method.cardNumber) ) {
			errors.cardNumber = "Please verify your credit card number";
		}

		if ( ! method.cvc ) {
			errors.cvc = "Security code must be specified";
		} else if ( ! method.cvc.match(/([0-9]{3,4})/) ) {
			errors.cvc = "Verify the security code";
		}

		if ( ! method.expiryMonth || ! method.expiryYear ) {
			errors.expiry = "Expiry date must be specified";
		} else {
			var now = new Date();
			var expiry = parseInt(method.expiryYear) * 100 + parseInt(method.expiryMonth);
			var current = now.getFullYear() * 100 + now.getMonth() +1;
			if ( expiry < current ) {
				errors.expiry = "Credit card must be currently valid";
			}
		}

		if ( ! $scope.$$phase ) $scope.$apply();

		var isValid = (Object.keys(errors).length == 0);
		$log.debug("v$verifyMethod: payment method is " + (isValid ? "valid" : "invalid"));
		if ( ! isValid ) $log.debug(JSON.stringify(errors));
		return isValid;
	}

	$scope.v$isCCValid = function(card) {
		if ( ! card ) return false;

		// remove any formatting
		card = card.replace(/[^0-9]/g,"");

		// Visa test card number - valid test account but will not pass Luhn check below
		if ( card.length == 13 && card.match(/4(2{12})/) ) return true;

		if ( card.length != 15 && card.length != 16 ) return false;

		if ( card.charAt(0) == "3" ) return false;

		// Luhn mod 10 check
		var sum = 0;
		for (var i = 0; i < card.length; i++) {
			var intVal = parseInt(card.substr(i, 1));
			if (i % 2 == 0) {
				intVal *= 2;
				if (intVal > 9) {
					intVal = 1 + (intVal % 10);
				}
			}
			sum += intVal;
		}

		return (sum % 10) == 0;
	}


	$scope.v$verifyContact = function(contact,options) {
		if ( ! contact ) return false;
		options = options || { require: { phone: true, email: true } };

		$log.debug("v$verifyContact: verify contact");
		contact.errors = {};
		var errors  = contact.errors;

		if ( ! contact.name || contact.name.split(" ").length < 2 ) {
			errors.name = "Full name must be specified";
		}

		if ( ! contact.street ) {
			errors.street = "Address must be specified";
		}
		if ( ! contact.city ) {
			errors.city = "City must be specified";
		}

		var nonUS = (contact.country && contact.country != "UNITED STATES");
		if ( ! nonUS ) {
			if ( ! contact.state ) {
				errors.state = "State must be specified";
			}
			if ( ! contact.zipcode ) {
				errors.zipcode = "Zipcode must be specified";
			} else {
				var tzip = contact.zipcode.replace(/[^0-9]/g, '')
				if ( tzip.length == 9 ) {
					contact.zipcode = tzip.replace(/([\d]{5})([\d]{4})(.*)/,"$1-$2");
				} else if ( tzip.length != 5 ) {
					errors.zipcode = "Please enter a valid zipcode";
				} else if ( tzip != contact.zipcode ) {
					contact.zipcde = tzip;
				}
			}
		}

		if ( options.require.phone && ! contact.phone ) {
			errors.phone = "Phone number must be specified";
		} else if ( ! nonUS && contact.phone ) {
			var tphone = contact.phone.replace(/[^0-9]/g, '');
			if ( tphone.length == 10 ) {
				contact.phone = tphone.replace(/([\d]{3})([\d]{3})([\d]{4})(.*)/,"($1) $2-$3 $4");
			} else if ( tphone.length == 11 && tphone.substring(1,1) == 1 ) {
				contact.phone = tphone.replace(/([\d]{1})([\d]{3})([\d]{3})([\d]{4})(.*)/,"$1 ($2) $3-$4");
			} else if ( tphone.length < 10 ) {
				errors.phone = "Please include the area code";
			}
		}

		if ( options.require.email || contact.email || contact.vemail ) {
			if ( ! contact.email ) {
				errors.email = "Email address must be specified";
			} else if ( contact.email.charAt(0) == "." || ! contact.email.match(/^.*[^\.]@[^\.].*\..+[^\.]$/) ) {
				errors.email = "Please enter a valid email";
			} else if ( ! contact.vemail ) {
				errors.vemail = "Please confirm your email address";
			} else if ( contact.email.toUpperCase() != contact.vemail.toUpperCase() ) {
				errors.vemail = "Email addresses must match";
			}
		}


		if ( ! $scope.$$phase ) $scope.$apply();

		var isValid = (Object.keys(errors).length == 0);
		$log.debug("v$verifyContact: contact is " + (isValid ? "valid" : "invalid"));
		if ( ! isValid ) $log.debug(JSON.stringify(errors));
		return isValid;
	}



	// VERY simplistic card type determination
	$scope.getCardType = function (cardnumber) {
		var cardtype = "";
		if ( cardnumber && cardnumber.length > 0 ) {
			cardnumber = cardnumber ? cardnumber.replace(/[^0-9]/g,"") : "";
			switch ( cardnumber.charAt(0) ) {
				case "4": cardtype = "Visa"; break;
				case "5": cardtype = "MasterCard"; break;
				case "6": cardtype = "Discover"; break;
				case "3": cardtype = "Amex"; break;
			}
		}

		return cardtype;
	}

	// User interaction methods
	//$scope.newSearch          = function() { window.location.href = $scope.payment.accountSearch; }

	// ////////////////////////////////////////////////////////////////
	// The following will display HTML from variables in the page
	// Define the following method in the controller:
	// 		$scope.renderHtml = function(htmlCode) { return $sce.trustAsHtml(htmlCode); };
	// Define the following html (or similar) in the HTML page:
	// 		<p ng-bind-html="renderHtml(error.description)"></p>
	// ////////////////////////////////////////////////////////////////
	//$scope.renderHtml = function(htmlCode) { $log.debug("Render"); return $sce.trustAsHtml(htmlCode); };


	//Client-side security. Server-side framework MUST add it's 
	//own security as well since client-based security is easily hacked
	//$rootScope.$on("$routeChangeStart", function (event, next, current) {
	//alert("Change"); alert(next);
	//});
	//$scope.isLoaded = false;

    $rootScope.$on('paymentAccounts loaded', 
            function(event,paymentAccounts) {
                $log.warn("App Controller: " + event.name + " event triggered");
	$scope.payment = paymentFactory.get();
    $scope.payment.status = $scope.status.READY;
            });

    if ( $rootScope.config.load == true  ) {
        $log.debug("Payment Controller: Retrieving configuration data");
        $scope.config = configFactory.get();
        if ( ! $scope.config ) {
            $log.debug("Payment Controller: Configuration data not loaded, redirecting to " + $scope.pages.CONFIG);
            $location.path($scope.pages.CONFIG);
            return;
        }
    }

	$log.debug("Payment Controller: Retrieving payment data");
	$scope.payment = paymentFactory.get();


	if ( ! $scope.payment ) {
		$log.debug("Payment Controller: Payment data not loaded, redirecting to " + $scope.pages.LOADDATA);
		$location.path($scope.pages.LOADDATA);
		return;
	}
	$log.debug("Payment Controller: Payment data available, redirecting to " + $scope.pages.ENTRY);
	$location.path($scope.pages.ENTRY);


	}]);