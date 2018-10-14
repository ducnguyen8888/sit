/*
{"status":"ERR","description":"Failed to retrieve data due to a processing error","detail":"java.net.UnknownHostException: chaos"}
*/
app.factory (
    "configFactory",
    function( $http, $q, $log, $rootScope, errorManager ) {
        var dataObject;

        // Sets the default URL
        var requestUrl = "control/getConfigData.jsp";

        // Return public API.
        return({
            load: load,
            get: get,
        });
        // ---
        // PUBLIC METHODS.
        // ---
        function get() {
            $log.debug("Config Factory: Get request");
            return dataObject;
        }

        function load(rid) {
            $log.debug("Config Factory: Load request - initial: " + requestUrl);
            $log.debug("Config Factory: Root: " + JSON.stringify($rootScope.config.urls));
            try {
                requestUrl = $rootScope.config.urls.configuration;
            } catch (err) {
                $log.debug("Using default load location");
            }
            $log.debug("Config Factory: Load request - final: " + requestUrl);

            var datarid = rid;
            $log.debug("Config Factory: rid - " + rid);
            var request = $http({
                method: "get",
                url: requestUrl + (datarid ? "?rid="+datarid : ""),
                params: {
                    action: "get"
                },
                data: {
                }
            });
            return( request.then( loadSuccess, loadError ) );
        }


        // ---
        // PRIVATE METHODS.
        // ---

        function loadError( response ) {
            $log.warn("Config Factory - Load request error response");
            $log.debug(JSON.stringify(response.data));

            if ( ! angular.isObject(response) ) {
                $log.debug("Config Factory: Unexpected response received, response is not an object");
                return ( $q.reject( response ) );
            }

            if ( ! angular.isObject(response.data) ) {
                $log.debug("Config Factory: Unexpected data received, response data is not an object");
                return ( $q.reject( { "status": "ERR", detail: response.status + " - " + response.statustext } ) );
            }

            return( $q.reject( response.data ) );
        }


        function loadSuccess( response ) {
            $log.debug("Config Factory - Load request success response");
            $log.debug(JSON.stringify(response.data));

            if ( ! angular.isObject(response) || ! angular.isObject(response.data) ) {
                $log.debug("Config Factory: Unexpected response received, response is not an object");
                return ( $q.reject( response.data ) );
            }

            if ( ! response.data.status ) {
                $log.debug("Config Factory: Response does not include the expected status field");
                return( $q.reject( response.data ) );
            }

            if ( response.data.status != "OK" ) {
                $log.debug("Config Factory: Invalid response status: " + response.data.status);
                return( $q.reject( response.data ) );
            }

            dataObject = response.data;
            $rootScope.$emit('configuration loaded', response.data.config);

            return response.data;
        }

    }
);
