// Service to keep server session alive
app.factory('HeartbeatService', function($interval, $http, $log) {
	function HeartbeatService($interval, $http, $log, uid, delay, url) {
		// "var" variables/functions are private and only accessible locally
		// "self" (this) are the externally accessible variables/functions

		var self = this;

		var id = (uid ? uid : "Heartbeat");
		self.setid = function(newid) { id = newid; }

		var delayTime = (delay && ! isNaN(delay) && delay >= 15000 ? delay : 300000); // default 5 minutes
		self.setdelay = function(delay) {
							if ( ! delay || isNaN(delay) ) throw "Invalid delay value specified";
							delay = new Number(delay);
							if ( delay < 15000 ) throw "Minimum delay allowed is 15000";
							delayTime = delay;
							self.restart();
						}
		var heartbeatUrl = (url ? url : "control/sessionNotice.jsp");
		self.seturl = function(url) { 
							if ( ! url ) throw "Invalid URL specified";
							heartbeatUrl = url;
						}


		var intervalPromise = null;

		var lastHeartbeat = 0;
		self.getlastHeartbeat = function() { return lastHeartbeat; }


		self.lastTripTime = 0;
		self.lastError    = null;

		self.onHeartbeat = null;

		self.next = function() { return delayTime - ((new Date()).getTime() - lastHeartbeat); }


		self.isrunning = function() { return intervalPromise != null; }
		self.restart = function() { self.stop(); self.start(); }
		self.stop = function() {
			if ( intervalPromise == null ) return;
			$log.debug((id ? id + ": " : "") + "Stopping");
			$interval.cancel(intervalPromise);
			intervalPromise = null;
		}
		self.start = function() {
			if ( intervalPromise != null ) return;
			$log.debug((id ? id + ": " : "") + "Starting, interval is set at " + delayTime + " ms");
			intervalPromise = $interval(heartbeat,delayTime);
		}

		var heartbeat = function() {
			lastHeartbeat = (new Date()).getTime();
			if ( ! heartbeatUrl ) {
				$log.error((id ? id + ": " : "") + "No URL set, stopping");
				self.stop();
				return;
			}
			$http.get(heartbeatUrl)
					.then(function(response) {
						self.lastTripTime = (new Date()).getTime() - lastHeartbeat;
						self.lastError = null;
						$log.debug((id ? id + ": " : "") + "Request completed");

						if ( self.onHeartbeat !== null ) {
							try {
								self.onHeartbeat(self.lastTripTime, (response.data ? response.data : null));
							} catch (err) {
							}
						}
					},function(response) {
						self.lastTripTime = (new Date()).getTime() - lastHeartbeat;
						$log.debug((id ? id + ": " : "") + "Received error response");
						$log.debug(response);
						if ( response.status == 404 || response.status == 500 ) {
							self.stop();
						}
						self.lastError = response.status + ": " + response.statusText;

						if ( self.onHeartbeat !== null ) {
							try {
								self.onHeartbeat(self.lastTripTime, response);
							} catch (err) {
							}
						}
					});
		};
		self.start();
	}
	function create(id, delay, url) {
		return new HeartbeatService($interval, $http, $log, id, delay, url);
	}
	//return new HeartbeatService($interval, $http, $log);
	return ({ create: create });
});


/*******
-- http://jsfiddle.net/dwmkerr/YZF4T/
-- Set the call in the application RUN block

// Create a simple controller that shows the ping.
app.controller('PingController', function($scope, HeartBeatService) {
    $scope.ping = null;
    HeartBeatService.onPingChanged = function(ping) {
        $scope.ping = ping;
    };
});


http://www.html5rocks.com/en/tutorials/cors/
withCredentials

Standard CORS requests do not send or set any cookies by default. In order to include cookies as part of the request, you need to set the XMLHttpRequest’s .withCredentials property to true:

xhr.withCredentials = true;
In order for this to work, the server must also enable credentials by setting the Access-Control-Allow-Credentials response header to “true”. See the server section for details.

Access-Control-Allow-Credentials: true
The .withCredentials property will include any cookies from the remote domain in the request, and it will also set any cookies from the remote domain. Note that these cookies still honor same-origin policies, so your JavaScript code can’t access the cookies from document.cookie or the response headers. They can only be controlled by the remote domain.


http://makandracards.com/makandra/31289-how-to-create-giant-memory-leaks-in-angularjs

**************/