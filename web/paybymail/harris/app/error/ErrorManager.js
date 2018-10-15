app.factory(
	"errorManager",
	function( $log, $location, $rootScope ) {
		var error    = { "title": "" };
		var last     = { error: error, source: "" };
		var defaults = {"title"        : "An Error Has Occurred",
					"summary"     : "We are unable to complete your request",
					"description" : "There was an issue serving your request, please try again in a few minutes.",
					"detail"      : "No further details are available for this error. If this problem continues please contact the tax office."
					};

		// Defines the public API
		return({
			raiseError:      raiseError,
			raiseStateError: raiseStateError,
			raiseDataError:  raiseDataError,

			error:           error,
			lastError:       last,
			defaults:        defaults
		});

		function raiseError(title, summary, description, detail, lognote) {
			error.title       = title       || defaults.title;
			error.summary     = summary     || defaults.summary;
			error.description = description || defaults.description;
			error.detail      = detail      || defaults.detail;

			last.lognote    = lognote;
			//last.source     = Function.caller || arguments.callee.caller.toString();

			if ( lognote ) $log.debug(lognote);
            $log.error("ErrorManager: Redirecting to error page");
			$location.path($rootScope.pages.ERROR);
		}

		function raiseStateError() {
			raiseError("Invalid State Information",
						"Invalid Account or Payment Information Was Found",
						"The internal state information we have is invalid, we are unable to continue with your payment",
						"<strong style='font-family:Arial'>Any pending payments are unaffected by this error. If you have made a payment "
							+ "please check the status on the <i>Account Information</i> page of the website.<br><br>"
							+ "If you have any questions about your account or this error please contact the Tax Office.</strong>"
					);
		}
		// Helper function, provides a consistent, single message to display for all missing payment data errors
		function raiseDataError() {
			raiseError("Invalid Account Information",
						"Account or Payment Information Was Found",
						"The internal data information we have is invalid, we are unable to continue with your payment",
						"<strong style='font-family:Arial'>Any pending payments are unaffected by this error. If you have made a payment "
							+ "please check the status on the <i>Account Information</i> page of the website.<br><br>"
							+ "If you have any questions about your account or this error please contact the Tax Office.</strong>"
					);

		}
	});
