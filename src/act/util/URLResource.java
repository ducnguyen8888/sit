package act.util;

import java.io.InputStream;
import java.io.OutputStream;

import java.net.HttpURLConnection;
import java.net.URL;

import java.net.URLEncoder;

import java.nio.charset.StandardCharsets;

import java.time.LocalDateTime;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

/**
 * User-Agent header will need to be defined if this is to appear as a browser. The
 * default User-Agent set shows the Java version:
 * <br>
 *          User-Agent: Java/1.8.0_101
 *
 */
public class URLResource extends Thread {
    public URLResource() {}
    public URLResource(String serverUrl) {
        this.serverUrl = serverUrl;
    }


    public static void main(String[] args) throws Exception {
        URLResource post = URLResource.initialContext()
       //.setUrl("http://apollo/act_webdev/_labs/oracle hash.txt")
       .setServerUrl("http://localhost:8080/minimal/postback.jsp")
                                .setPostData("AAAA=1&BBBB=2")
                                .submit()
                                ;
       System.out.println(post.getResponseHeaders());
       System.out.println(post.toString());
   }


    public String                       serverUrl               = null;
    public String                       contentType             = null;
    public String                       postData                = null;
    public Map<String, List<String>>    headers                 = null;
                        
    public int                          connectTimeout          = 5000;
    public int                          readTimeout             = 10000;

    public LocalDateTime                requestTimestamp        = null;
    public int                          responseCode            = 0;
    public String                       response                = null;
    public Map<String, List<String>>    responseHeaders         = null;
    public long                         duration                = 0;
    public Exception                    submissionException     = null;

    public boolean isSuccessful() { 
        return responseCode == 200;
    }

    public URLResource resetResponse() { 
        requestTimestamp        = null;
        responseCode            = 0;
        response                = null;
        responseHeaders         = null;
        duration                = 0;
        submissionException     = null;
        return new URLResource();
    }



    public static URLResource initialContext() { 
        return new URLResource();
    }
    public static URLResource initialContext(URLResource httpPost) {
        URLResource newHttpPost         = new URLResource();
        newHttpPost.serverUrl           = httpPost.serverUrl;
        newHttpPost.contentType         = httpPost.contentType;
        newHttpPost.postData            = httpPost.postData;
        if ( httpPost.headers != null ) {
            newHttpPost.headers         = new Hashtable<String, List<String>>(httpPost.headers);
        }

        newHttpPost.connectTimeout      = httpPost.connectTimeout;
        newHttpPost.readTimeout         = httpPost.readTimeout;

        return newHttpPost;
    }


    public String getResponseHeaders() {
        if ( responseHeaders == null ) return "";

        StringBuilder builder = new StringBuilder();

        // The 'null' response header is the HTTP response string
        if ( responseHeaders.containsKey(null) ) {
            responseHeaders.get(null).forEach((v) -> builder.append(String.format("%s\n",v)));
        }
        responseHeaders.forEach( (k,l) -> l.forEach((v) -> { if ( k == null ) return; builder.append(String.format("%s: %s\n",k,v)); } ) );

        return builder.toString();
    }

    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("Host:          " + serverUrl + "\n");
        builder.append("Submitted:     " + requestTimestamp.toString() + "\n");
        builder.append("Duration:      " + (duration/1000) + " ms\n");
        builder.append("Data:          " + postData + "\n");
        builder.append("Response Code: " + responseCode + "\n");
        builder.append("Response Text:\n" + response + "\n");
        if ( submissionException != null ) 
            builder.append("Exception:    " + submissionException + "\n");
        return builder.toString();
    }


    public URLResource setServerUrl(String serverUrl) { 
        this.serverUrl = serverUrl; 
        return this; 
    }
    public URLResource setTimeout(int connectTimeout, int readTimeout) { 
        this.connectTimeout = connectTimeout; 
        this.readTimeout    = readTimeout; 
        return this; 
    }
    public URLResource setPostData(String postData) { 
        this.postData = postData;
        return this; 
    }

    public URLResource clearHeaders() {
        this.headers.clear();
        return this;
    }
    public URLResource clearHeader(String header) {
        this.headers.remove(header);
        return this;
    }
    public URLResource addHeader(String header, String value) { 
        if ( this.headers == null ) {
            this.headers = new Hashtable<String, List<String>>();
        }

        if ( ! this.headers.containsKey(header) ) {
            this.headers.put(header, new ArrayList<String>());
        }
        this.headers.get(header).add(value);

        return this; 
    }
    public URLResource addParameter(String parameter, String value) throws Exception {
        if ( notDefined(this.contentType) ) 
            setContentType("application/x-www-form-urlencoded; charset=utf-8");

        this.postData = String.format("%s%s=%s",
                                        (isDefined(this.postData) ? String.format("%s&",this.postData) : ""),
                                        URLEncoder.encode(parameter, StandardCharsets.UTF_8.displayName()),
                                        URLEncoder.encode(value, StandardCharsets.UTF_8.displayName())
                                      );
        return this;
    }

    // Common Content-Type values:
    //      application/json; charset=utf-8
    //      text/html; charset=utf-8
    //      application/x-www-form-urlencoded; charset=utf-8
    public URLResource setContentType(String contentType) {
        this.contentType = contentType;
        return this;
    }



    public void run() {
        try {
            submit();
        } catch (Exception exception) {
            if ( submissionException == null ) {
                submissionException = exception;
            }
        }
    }


    public URLResource submit() {
        long start = System.currentTimeMillis();

        try {
            resetResponse();
            requestTimestamp = LocalDateTime.now();

            // Open the URL
            HttpURLConnection.setFollowRedirects(false);
            URL url = new URL(serverUrl);
            HttpURLConnection.setFollowRedirects(false);
            HttpURLConnection urlConn = (HttpURLConnection) url.openConnection();
            urlConn.setUseCaches(false);

            // Set our headers
            if ( headers != null ) {
                headers.forEach( (k,l) -> l.forEach((v) -> urlConn.setRequestProperty(k,v)) );
            }

            if ( postData != null ) {
                urlConn.setDoOutput(true);
                urlConn.setRequestMethod("POST");

                if ( isDefined(contentType) )
                    urlConn.setRequestProperty("Content-Type",contentType);
                //urlConn.setRequestProperty("charset", StandardCharsets.UTF_8.displayName());
                urlConn.setRequestProperty("Content-Length",""+postData.length());


                try ( OutputStream out = urlConn.getOutputStream(); ) {
                    out.write(postData.getBytes("UTF-8"));
                    out.flush();
                } catch (Exception e) {
                    throw e;
                }
            }

            urlConn.setConnectTimeout(connectTimeout);
            urlConn.setReadTimeout(readTimeout);

            // Submit the request
            responseCode = urlConn.getResponseCode();
            response     = readInput(urlConn.getInputStream());

            responseHeaders = urlConn.getHeaderFields();
            //if ( urlConn.getResponseCode() == HttpURLConnection.HTTP_OK ) {
            //    responseHeaders = urlConn.getHeaderFields();
            //}

            duration     = System.currentTimeMillis() - start;
        } catch (Exception e) {
            submissionException = e;
        } finally {
            duration = System.currentTimeMillis() - start;
        }

        return this;
    }

    public boolean isDefined(String value) {
        return value != null && value.length() > 0;
    }
    public boolean notDefined(String value) {
        return value == null || value.length() == 0;
    }

    public String readInput(InputStream is) throws Exception {
        StringBuilder builder = new StringBuilder();

        int readSize = 0;
        byte [] data = new byte[8192];
        while ( (readSize=is.read(data)) != -1 ) builder.append(new String(data,0,readSize));

        return builder.toString();
    }

}
