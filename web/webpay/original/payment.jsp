<%--

    referenceUrl
    Tax Office name
    seal
    isTest
    merchantKey
    phone required 
    email required
    fee amount/percentage
        How do we identify the fee amount to be charged/paid?
        We don't know whether this is an EC or a CC.


    <base href="/pds/payment.jsp">
        -- replaced with --
    <base href="<%= request.getRequestURI() %>">

--%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma" , "no-cache");
    response.setDateHeader("Expires", 0);

    if ( false ) {
        java.util.Map x = request.getParameterMap();
        String [] keys = (String[]) x.keySet().toArray(new String[0]);
        for ( String key : keys ) {
            %><li> (<%= key %>): (<%= request.getParameter(key) %>)</li><%
        }

        if ( true ) return;
    }


    String uid = ""+(new java.util.Date()).getTime();
    String rid = request.getParameter("rid");

%><!DOCTYPE html>
<html lang="en" ng-app="WebsitePayment" ng-controller="PaymentController">
<head>
    <!-- <meta charset="utf-8"> for non html5 pages -->
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>SIT Payment</title>
    <base href="<%= request.getRequestURI() %>">

    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="css/ngDialog.css" rel="stylesheet">
    <link href="css/font-awesome-4.3.0/css/font-awesome.min.css" rel="stylesheet">
    <link href="css/payment.css" rel="stylesheet">

    <style>
    </style>
</head>
<body>
    <div style="background-color:#e4e4e4;height:76px;width:100%; margin-bottom: 30px;">
        <div style="width:960px;margin:0 auto;">
            <div style="display:inline-block;width:50%;">
                <div style="display:inline-block;height:100%;vertical-align:middle;padding-top:20px;font-size:20px;font-weight: bold; padding-left:5px;color:darkblue;">
                    Special Inventory Tax<br><div style="font-size:14px;font-style:italic;">Online Payments</div>
                </div>
            </div>
            <div style="display:inline-block;position: absolute; right: 25px; float:right;margin-top:15px;font-size:13px;">
                <a href="../pay.jsp" 
				style="color:#FFF;color:#000;float:right;font-size:16px;">
                    Back to Special Inventory Tax &raquo;
                </a>
            </div>
        </div>
    </div>

    <div class="content">
        <div>
            <div id="viewBlock" ng-view></div>
        </div>
    </div>

    <script src="js/jquery-1.9.1.min.js"></script>
    <script src="js/bootstrap.min.js"></script>
    <script src="js/angular.js"></script>
    <script src="js/ngDialog.js"></script>
    <script src="js/angular-route.js"></script>
    <link  href="js/SmartWizard/smart_wizard.css?<%= uid %>" type="text/css" rel="stylesheet" />
    <script src="js/SmartWizard/jquery.smartWizard.js"></script>
    <script>
        $(function() {
        });
        var app = angular.module("WebsitePayment", ["ngRoute","ngDialog"]);
        app.config(function($provide,$logProvider) {
                $logProvider.debugEnabled(true);
                $provide.decorator('$controller', function($delegate) {
                return function(constructor, locals, later, indent) {
                    if (typeof constructor === 'string' && !locals.$scope.controllerName) {
                        locals.$scope.controllerName =  constructor;
                    }
                    return $delegate(constructor, locals, later, indent);
                };
            });
        });
    </script>
    <script src="app/shared/HeartbeatService.js?<%= uid %>"></script>
    <script src="app/shared/ConfigFactory.js?<%= uid %>"></script>
    <script src="app/shared/PaymentFactory.js?<%= uid %>"></script>
    <script src="app/shared/directives.js?<%= uid %>"></script>
    <script src="app/shared/filters.js?<%= uid %>"></script>
    <script src="app/PaymentController.js?<%= uid %>"></script>
    <script src="app/error/ErrorManager.js?<%= uid %>"></script>
    <script src="app/error/ErrorController.js?<%= uid %>"></script>
    <script src="app/config/ConfigController.js?<%= uid %>"></script>
    <script src="app/load/LoadController.js?<%= uid %>"></script>
    <script src="app/entry/EntryController.js?<%= uid %>"></script>
    <script src="app/verify/VerifyController.js?<%= uid %>"></script>
    <script src="app/process/ProcessController.js?<%= uid %>"></script>
    <script src="app/failure/FailureController.js?<%= uid %>"></script>

    <script src="app/success/SuccessController.js?<%= uid %>"></script>

    <script src="app/checkout/vendor/jpmc/process/JPMCProcessController.js?<%= uid %>"></script>
    <script src="app/checkout/vendor/jpmc/success/JPMCKickoffController.js?<%= uid %>"></script>

    <script>
        app.run( function($rootScope, $location, $log, $injector, errorManager, HeartbeatService, $interval, $http, $timeout) {
            $log.debug("Application Start: " + $("html").attr("ng-app"));

            // Function called in $exceptionHandler logging (see below)
            $injector.get("$rootScope").addExceptionAlert = function(obj) { alert(obj.reason); };


            // Used to easily standardize the status and routes across all pages. This
            // way the individual controllers don't need to worry about how the
            // reference valures are actually expressed.
            $rootScope.status = {
                            FRESH:       "Fresh",
                            READY:       "Ready",
                            VERIFIED:    "Verified",
                            PROCESSING:  "Processing",
                            SUCCESS:     "Success",
                            FAILURE:     "Failure"
                            };

            $rootScope.pages = {
                            CONFIG:      "/config",
                            LOADDATA:    "/load",
                            ERROR:       "/error",
                            ENTRY:       "/entry",
                            VERIFY:      "/verify",
                            PROCESS:     "/processing",
                            SUCCESS:     "/success",
                            FAILURE:     "/failure"
                            };

            $rootScope.config = {
                            load: true,
                            urls: { getConfig: "control/getConfigData.jsp" }
                            };

            $rootScope.$on('configuration loaded', function(event,configuration) {
                $log.warn(event.name + " event triggered");
                angular.extend($rootScope.config,configuration);
                if ( $rootScope.config.urls.hBeat && ! $rootScope.pp ) {
                    $rootScope.pp = HeartbeatService.create("hBeat",0,$rootScope.config.urls.hBeat);
                }

                if ( $rootScope.config.clientId == configuration.clientId ) {
                    // Update our client URL if necessary
                    if ( configuration.clientRoot ) 
                        $rootScope.clientRoot = configuration.clientRoot;
                    // Update our account search URL if necessary
                    if ( configuration.accountSearchUrl ) 
                        $rootScope.accountSearchUrl = configuration.accountSearchUrl;
                }

                if ( configuration.processor.id == "JPMC" ) {
                    $rootScope.pages.PROCESS = "/processJPMC";
                    $rootScope.pages.SUCCESS = "/JPMC";
                }
            });

            $rootScope.$on('paymentAccounts loaded', function(event,paymentAccounts) {
                $log.warn(event.name + " event triggered");
// For Testing only
$rootScope.rid = paymentAccounts.RID;
$log.debug("CID is " + paymentAccounts.client_id);
$rootScope.config.clientId = paymentAccounts.client_id;
$log.debug("Client: " + $rootScope.config.clientId);
                // Make sure the session and account client matches what we expect, otherwise 
                // raise an errr to prevent incorrect or problem system updates
                if ( $rootScope.config.clientId != paymentAccounts.client_id || $rootScope.rid != paymentAccounts.RID ) {
                    $log.warn("Invalid client or session");
                    errorManager.raiseError(
                            "No Accounts Found",
                            "We did not find any accounts to pay",
                            "No accounts to pay were found, this may be due to your "
                                                + "browser session timing out. Please try again",
                            ""
                        );
                    // Since we are in an event trigger we can't directly stop normal execution
                    $rootScope.stopApplication = true;
                    $timeout(function() { $location.path($rootScope.pages.ERROR); },1);
                    return;
                }

                paymentAccounts.clientRoot       = $rootScope.clientRoot;
                paymentAccounts.accountSearchUrl = $rootScope.accountSearchUrl;
                paymentAccounts.processor        = $rootScope.config.processor;
            });


            // Ensure that our navigation doesn't continue if we've flagged the application to stop
            $rootScope.$on( "$locationChangeStart", function(event, next, current) {
                $log.debug("Location change.\nFrom: " + current + "\n  To: " + next);
                if ( $rootScope.stopApplication && $location.path() != "/error") {
                    $log.info("Global application error has been flagged, cancelling location change");
                    event.preventDefault();
                    return;
                }
            });

            // Verify that we'll be able to location our payment information
            $log.debug("Application: Verifying RID");
            $rootScope.rid = ($location.search()["rid"] ? $location.search()["rid"] : "<%= rid %>"); // html5 mode must be enabled for this to work
            if ( ! $rootScope.rid || $rootScope.rid.length == 0 ) {
                $log.debug("Application: RID failure, redirecting to " + $rootScope.pages.ERROR);
                $rootScope.stopApplication = true;
                errorManager.raiseError("Payments Unavailable",
                                "Payments are unavailable at this time",
                                "No payment session is configured, please try again");
                return;
            }

            $log.debug("Application: Ready");
        });



/*
app.filter('iif', function () {
   return function(input, trueValue, falseValue) {
        return input ? trueValue : falseValue;
   };
});
*/

app.fff = function(e) { alert(e); }
app.filter('tel', function () {
    return function (phoneNumber) {
        if (!phoneNumber)
            return phoneNumber;

            return phoneNumber.replace(/([\d]{0,3})([\d]{0,3})([\d]{0,4})(.*)/,"($1) $2-$3");
        //return formatLocal('US', phoneNumber); 
    }
});



app.config(['$routeProvider','$locationProvider',
    function($routeProvider,$locationProvider) {
        $locationProvider.html5Mode(false);
        $routeProvider
                .when('/config', {
                    templateUrl: 'app/config/ConfigFrame.html?'+Date.now(),
                    controller: 'ConfigController'
                })
                .when('/load', {
                    templateUrl: 'app/load/LoadFrame.html?'+Date.now(),
                    controller: 'LoadController'
                })
                .when('/error', {
                    templateUrl: 'app/error/ErrorFrame.html?'+Date.now(),
                    controller: 'ErrorController'
                })
                .when('/entry', {
                    templateUrl: 'app/entry/EntryFrame.html?'+Date.now(),
                    controller: "EntryController"
                    //resolve: {
                    //	initialData: function($log, paymentFactory) { return paymentFactory.get(1); }
                    //}
                })

                .when('/verify', {
                    templateUrl: 'app/verify/VerifyFrame.html?'+Date.now(),
                    controller: "VerifyController"
                })


                .when('/processing', {
                    templateUrl: 'app/process/ProcessFrame.html?'+Date.now(),
                    controller: 'ProcessController'
                })
                .when('/success', {
                    templateUrl: 'app/success/SuccessFrame.html?'+Date.now(),
                    controller: 'SuccessController'
                })
                .when('/failure', {
                    templateUrl: 'app/failure/FailureFrame.html?'+Date.now(),
                    controller: 'FailureController'
                //})
                //.otherwise({
                //    redirectTo: "/entry"
                })
                .when('/processJPMC', {
                    templateUrl: 'app/checkout/vendor/jpmc/process/JPMCProcessFrame.html?'+Date.now(),
                    controller: 'JPMCProcessController'
                })
                .when('/JPMC', {
                    templateUrl: 'app/checkout/vendor/jpmc/success/JPMCKickoffFrame.html?'+Date.now(),
                    controller: 'JPMCKickoffController'
                })
                ;
}]);


app.config(function ($provide) {
    $provide.decorator("$exceptionHandler", function ($delegate, $injector) {
        return function (exception, cause) {
            var $rootScope = $injector.get("$rootScope");
            $rootScope.addExceptionAlert({message: "Exception", reason: exception}); // This represents a custom method that exists within $rootScope
            $delegate(exception, cause);
        };
    });
});

app.config(['$provide', function ($provide) {
        $provide.decorator('$log', ['$delegate', function ($delegate) {
            // Keep track of the original debug method, we'll need it later.
            var origError = $delegate.error;
            /*
             * Intercept the call to $log.debug() so we can add on 
             * our enhancement. We're going to add on a date and 
             * time stamp to the message that will be logged.
             */
            $delegate.error = function () {
                var args = [].slice.call(arguments);
                args[0] = [new Date().toString(), ': ', args[0]].join('');

                // Send on our enhanced message to the original debug method.
                origError.apply(null, args)
            };

            return $delegate;
        }]);
    }]);
</script>

    <style scoped>

    </style>

</body>
</html>
