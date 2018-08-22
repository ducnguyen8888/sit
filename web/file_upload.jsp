<%@ include file="_configuration.inc"%>
<% 
    String pageTitle = "File Upload";
    String username = (String) session.getAttribute( "username");
    String client_id = nvl(request.getParameter("client_id"), (String) session.getAttribute( "client_id"));
    String comment = nvl(request.getParameter("comment"), null);
    boolean commentUpdated = false;
    month = nvl(request.getParameter("month"), (String) session.getAttribute( "uMonth"));
    year = nvl(request.getParameter("year"), (String) session.getAttribute( "uYear"));
    can = nvl(request.getParameter("can"), (String) session.getAttribute( "uCan"));
    String key_seq = nvl(request.getParameter("key_seq"), "01");
    StringBuffer sb = new StringBuffer();
    //sb.append("key_seq (" + key_seq + "), comment (" + comment + "), month (" + month + "), year (" + year + "), can (" + can + ")<br>");
    int report_sequence =  (request.getParameter("report_seq") != null) ? Integer.parseInt(request.getParameter("report_seq")) : 1; // I need to create this for CREATE
    boolean showWaccount = true;
    boolean showWyearSelect = false;
    boolean showWyearDisplay = false;
    boolean showWyearMonthDisplay = false;
    boolean showUpload = false;

    if(can != null){ 
        boolean foundD = false;
        int i = 0;
        while ( !foundD && i < ds.size() ){
            d = (Dealership) ds.get(i);
            if (can.equals(d.can)) foundD = true; else i++;
        }
    }
    if (isDefined(comment)){
        commentUpdated = updateComment(client_id, key_seq, username, comment);
    }
    byte LF   = '\r';
    byte EOL  = '\n';

    int  sidx = 0, cidx = 0, eidx = 0; // Used to walk through the content data
    int  idx  = 0; // Simple string search index

    boolean isFile      = false,
            wasUploaded = false;

    byte [] requestData = null;
    String boundary = null;
    String endBoundary = null;


    String prc_number = nvl(request.getParameter("prc"),""); // "30771";
    boolean isFileUpload = "Y".equals(request.getParameter("upload"));

    String filename  = null,
           paramname = null;

    String user_message = null;


    if ( isFileUpload ) {
        try {
            // Verify the request
            try {
                if ( request.getContentLength() <= 0 ) 
                    throw new InstantiationException("Missing content data");
                if ( request.getContentLength() > Integer.MAX_VALUE ) 
                    throw new InstantiationException("Excessive data size. Maximum data size is " + Integer.MAX_VALUE);

                if ( request.getContentType() == null ) // Page called directly, there's no data
                    throw new InstantiationException("Missing content type");
                if ( request.getContentType().indexOf("multipart/form-data") < 0 ) 
                    throw new InstantiationException("Invalid content type. Content type must be multipart/form-data.");
            } catch (Exception e) {
                throw extendException(e, "Verifying request");
            }


            // Read all the data
            DataInputStream is = null;
            try {
                requestData = new byte [(int) request.getContentLength()];
                is = new DataInputStream(request.getInputStream());
                int bytesRead = 0, readSize = requestData.length;
                while ( bytesRead < requestData.length && readSize >= 0 ) {
                    readSize = requestData.length-bytesRead;
                    readSize = is.read(requestData,bytesRead,readSize);
                    bytesRead += readSize;
                }

                if ( bytesRead != requestData.length )
                    throw new InstantiationException("Failed to read all content");
            } catch (Exception e) {
                throw extendException(e, "Reading request data");
            } finally {
                try { is.close(); } catch (Exception e) {} is = null;
            }


            try {
                // Determine the boundary marker -- the boundary marker listed in the content type header is not complete
                while ( sidx < requestData.length-2 && requestData[sidx] != LF && requestData[sidx+1] != EOL ) sidx++;
                boundary = new String(requestData,0,sidx);
                endBoundary = boundary + "--"; // End boundary is the boundary with two additional dashes added to the end
                sidx += 2;


                // Loop through the data and process
                while ( sidx < requestData.length ) {
                    filename = paramname = null;
                    isFile   = false;

                    // ////// At this point we should be at the line just after the boundary marker, which will be the Content-Disposition


                    // Retrieve and process the content-disposition, determine if this is a file or a parameter
                    eidx = sidx;
                    while ( eidx < requestData.length-2 && requestData[eidx] != LF && requestData[eidx+1] != EOL ) eidx++;
                    String contentDisposition = new String(requestData,sidx,eidx-sidx);
                    
                    if ( ! contentDisposition.startsWith("Content-Disposition: form-data; ") )
                        throw new InstantiationException("Data error. Failed to find content disposition");

                    // Is this a file? or a parameter?
                    if ( (idx = contentDisposition.indexOf("; filename=")) > 0 ) {
                        isFile = true;
                        filename = contentDisposition.substring(idx+12,contentDisposition.length()-1).replaceAll("\\\\","/");
                        if ( (idx = filename.lastIndexOf("/")) > 0 ) filename = filename.substring(idx+1);
                        if ( ! isDefined(filename) )
                            throw new InstantiationException("Data error. No filename, file may not have been specified.");

                        // Get the content type
                        sidx = eidx += 2;
                        while ( eidx < requestData.length-2 && requestData[eidx] != LF && requestData[eidx+1] != EOL ) eidx++;
                        String contentType = new String(requestData,sidx,eidx-sidx);
                        if ( ! contentType.startsWith("Content-Type: ") )
                            throw new InstantiationException("Data error. Failed to find content type for " + filename);
                        contentType = contentType.substring(14);
                    } else {
                        idx = contentDisposition.indexOf("; name=");
                        paramname = contentDisposition.substring(idx+8,contentDisposition.length()-1);
                    }
                    sidx = cidx = eidx += 4; // skip past end of current line and following blank line


                    // Determine the bounds of our data by locating the next boundary marker
                    String cmpString = null;
                    while ( cidx <  requestData.length ) {
                        while ( eidx < requestData.length-2 && requestData[eidx] != LF && requestData[eidx+1] != EOL ) eidx++;

                        cmpString = new String(requestData,cidx,eidx-cidx);
                        if ( boundary.equals(cmpString) || endBoundary.equals(cmpString) ) {
                            break;
                        }
                        cidx = eidx += 2;
                    }
                    cidx -= 2; // Skip back to before blank line that ends the data


                    // Upload data to database
                    if ( isFile ) {
                        if ( sidx == cidx )
                            throw new InstantiationException("Data error. No data for file " + filename + ". File may have been empty.");
                        key_seq = String.valueOf(uploadFile(datasource, client_id, requestData,sidx,cidx-sidx, month, year, can, username, report_sequence));
                        wasUploaded = true;
                        break;
                    }

                    sidx = eidx+2; // Move past the end of the current line
                }
            } catch (Exception e) {
                throw extendException(e, "Processing request data");
            }


            if ( ! wasUploaded )
                throw new InstantiationException("Data error. No file data. File may not have been specified.");

        } catch (Exception e) {
            user_message = e.toString();
        }
    }
%><%!

    Exception extendException(Exception e, String additionalMessage)
             throws NoSuchMethodException, InstantiationException, 
                    IllegalAccessException, java.lang.reflect.InvocationTargetException {
        return (Exception) e.getClass().getConstructor(new Class[]{(new String()).getClass()})
                    .newInstance(new String[]{additionalMessage + ". " + e.getMessage()});
    }

    boolean updateComment(String client_id, String key_seq, String username, String comment){
        boolean updated = false;
        if(!"".equals(comment)){
            Connection conn = null;
            PreparedStatement ps = null;
            try{
                try {
                    conn = connect();
                } catch (Exception e) {
                    throw extendException(e, "Connecting to database for update");
                } 
                try {
                    ps = conn.prepareStatement("update sit_documents set comments=?, opercode=? where client_id=? and key_seq=?");
                    ps.setString(1, comment);
                    ps.setString(2, "WEB - " + username);
                    ps.setString(3, client_id);
                    ps.setString(4, key_seq);
                    updated = (ps.executeUpdate() > 0);
                } catch (Exception e) {
                    SITLog.error(e, "updating comment in file_upload");
                } finally {
                    try { ps.close(); } catch (Exception e) {} ps = null;
                }
            } catch (Exception e) {
                SITLog.error(e, "Big outer for comment update in file_upload");
            } finally {
                try { ps.close(); } catch (Exception e) {} ps = null;
                try { conn.close(); } catch (Exception e) {} conn = null;
            }   
        }//if (!"".equals(comment))

        return updated;
    }
    long uploadFile(String datasource, String client_id, byte [] fileBlob, int startpos, int length, String month, String year, String can, String username, int report_sequence ) throws Exception {
        Connection conn = null;

        try {
            conn = connect();
            return uploadFile(conn, client_id, fileBlob, startpos, length, month, year, can, username, report_sequence);
        } catch (Exception e) {
            throw extendException(e, "Connecting to database");
        } finally {
            try { conn.close(); } catch (Exception e) {} conn = null;
        }

    }



    long uploadFile(Connection conn, String client_id, byte [] fileBlob, int startpos, int length, String month, String year, String can, String username, int report_sequence  ) throws Exception {
        PreparedStatement ps = null;
        Statement         st = null;
        ResultSet         rs = null;
        OutputStream      os = null;
        long              millis = System.currentTimeMillis() / 1000;
        long              key_seq = 0l;
        boolean           recordExists = false;
        month = month.length() == 1 ? "0" + month : month; // makes 7 = 07

        try {
            //check if a document already exists
            try {
                ps = conn.prepareStatement("select key_seq from sit_documents where client_id=? and key_year=? and reference_no=?");
                ps.setString(1, client_id); 
                ps.setString(2, year); 
                ps.setString(3, month);
                rs = ps.executeQuery();
                if(rs.next()){
                    key_seq = rs.getLong(1);
                    recordExists = true;
                }
            } catch (Exception e) {
                throw extendException(e, "Retrieve attachment id");
            } finally {
                try { rs.close(); } catch (Exception e) {} rs = null;
                try { ps.close(); } catch (Exception e) {} ps = null;
            }            
            //if exists, delete it
            if(recordExists){
                try {
                    ps = conn.prepareStatement("delete from sit_documents where client_id=? and key_seq=?");
                    ps.setString(1, client_id);
                    ps.setLong(2, key_seq);
                    ps.executeUpdate();
                } catch (Exception e) {
                    SITLog.error(e, "deleting from sit_documents in file_upload");
                } finally {
                    try { rs.close(); } catch (Exception e) {} rs = null;
                    try { ps.close(); } catch (Exception e) {} ps = null;
                }          
                try {
                    ps = conn.prepareStatement("delete from sit_document_images where client_id=? and key_seq=?");
                    ps.setString(1, client_id);
                    ps.setLong(2, key_seq);
                    ps.executeUpdate();                    
                } catch (Exception e) {
                    SITLog.error(e, "deleting from sit_document_images in file_upload");
                } finally {
                    try { rs.close(); } catch (Exception e) {} rs = null;
                    try { ps.close(); } catch (Exception e) {} ps = null;
                }          

            }//if(recordExists)

            // Determine the next attachment ID
            try {
                st = conn.createStatement();
                //rs = st.executeQuery("select max(key_seq)+1 from sit_document_images");
                rs = st.executeQuery("select document_seq.nextval from dual");
                rs.next();
                key_seq = rs.getLong(1);
            } catch (Exception e) {
                SITLog.error(e, "select document_seq.nextval from dual");
            } finally {
                try { rs.close(); } catch (Exception e) {} rs = null;
                try { st.close(); } catch (Exception e) {} st = null;
            }

            // Create skeleton record
            try {
                ps = conn.prepareStatement("insert into sit_document_images (client_id, key_seq, file_blob, file_name, access_count, opercode) VALUES (?,?,EMPTY_BLOB(),?,?,?)");
                ps.setString(1, client_id); //client_id
                ps.setLong(2, key_seq); //key_seq
                ps.setString(3, "SIT_ADDL_"+millis+".pdf");//file_name
                ps.setInt(4, 0);
                ps.setString(5, "WEB - " + username);
                ps.executeUpdate();
            } catch (Exception e) {
                SITLog.error(e, "Create skeleton record");
            } finally {
                try { ps.close(); } catch (Exception e) {} ps = null;
            }

            // Store the file
            try {
                ps = conn.prepareStatement("select file_blob from sit_document_images where client_id = ? and key_seq = ? for update");
                ps.setString(1,client_id);
                ps.setLong  (2,key_seq);
                rs = ps.executeQuery();
                rs.next();

                // os = ((oracle.sql.BLOB) (rs.getBlob(1))).getBinaryOutputStream();
                os = rs.getBlob(1).setBinaryStream(1l);
                os.write(fileBlob,startpos,length);
                os.flush();
            } catch (Exception e) {
                throw extendException(e, "Uploading data");
            } finally {
                try { os.close(); } catch (Exception e) {} os = null;

                try { rs.close(); } catch (Exception e) {} rs = null;
                try { ps.close(); } catch (Exception e) {} ps = null;
            }


            try {
                String months [] = { null , "JAN" , "FEB" , "MAR" , "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" };
                String description = months[Integer.parseInt(month)] + " " + year + " SALES REPORT - WEB DEALER UPLOAD";

                ps = conn.prepareStatement(""
                          + "insert into sit_documents "
                          + "(client_id, comments, description, document_type, event_seq, key_id, key_seq, key_type, key_year, reference_no, opercode) VALUES "
                          + "(?,'ADDED: ' || sysdate,?,?,?,?,?,?,?,?,?)" );
                ps.setString(1, client_id); //client_id
                ps.setString(2, description); //description
                ps.setString(3, "MONRPT"); //document_type
                ps.setInt(4, report_sequence); //event_seq &report_seq?
                ps.setString(5, can); //key_id
                ps.setLong(6, key_seq); //key_seq
                ps.setString(7, "A"); //key_type
                ps.setString(8, year); //key_year
                ps.setString(9, month);
                ps.setString(10, "WEB - " + username);

               //ps.executeUpdate();
               if( ps.executeUpdate() > 0){
                  //SITLog.info("added addl into sit_dox");
               } else {
                  //SITLog.info("FAILED on adding addl into sit_dox");
               }
               
            } catch (Exception e) {
                throw extendException(e, "Create skeleton record");
            } finally {
                try { ps.close(); } catch (Exception e) {} ps = null;
            }


        } catch (Exception e) {
                    SITLog.error(e, "final exception in file_upload.jsp");
            throw extendException(e, "Upload file");

        } finally {
            if ( os != null ) { try { os.close(); } catch (Exception e) {} os = null; }

            if ( rs != null ) { try { rs.close(); } catch (Exception e) {} rs = null; }
            if ( ps != null ) { try { ps.close(); } catch (Exception e) {} ps = null; }
            if ( st != null ) { try { st.close(); } catch (Exception e) {} st = null; }
        }
        return key_seq;
    }
%>

<%@ include file="_top1.inc" %>
<!-- include styles here -->
<style>
    #createSaleForm label { font-size: 11px; }
    #bodyTop { height: 300px; }
    #body { top: 380px;  border-top: 1px solid #808080; }
    #myTableDiv { margin-left: 150px;}
    #formDiv { padding-top: 170px; width:600px; }
    .error { border: 1px solid red; }
    .errorText { color: red; }
</style>
        <%@ include file="_top2.inc" %>
        <%= recents %>
        <%@ include file="_widgets.inc" %>

        <div id="formDiv">
            <button style="margin-left: 40px;" id="btnPrev" name="btnPrev" class="btn btn-primary"><i class="fa fa-arrow-left"></i> back to Sales</button>
        </div>

    </div> <!-- #bodyTop -->

   <div id="body" >
        <div id="myTableDiv">
            <% if (commentUpdated) out.print("<strong>your comment has been updated</strong>"); %><br>
            Enter any comment you wish to be associated with your file upload.
            <form id="navigation"  action="file_upload.jsp" method="post">
                <input type="hidden" name="client_id" id="client_id" value="<%= client_id %>">
                <input type="hidden" name="can" id="can" value="<%= can %>">
                <input type="hidden" name="report_seq" id="report_seq" value="<%= report_sequence %>">
                <input type="hidden" name="year" id="year" value="<%= year %>">
                <input type="hidden" name="month" id="month" value="<%= month %>">
                <input type="hidden" name="key_seq" id="key_seq" value="<%= key_seq %>">
                <input type="hidden" name="current_page" id="current_page" value="<%= current_page %>">
                <textarea name="comment" rows="4" cols="50"></textarea><br>
                <button type="submit">Add Comment</button>
            </form>       
        </div><!-- myTableDiv -->
    </div><!-- /body -->



 
<%@ include file="_bottom.inc" %>
<!-- include scripts here -->
    <script>
        $(document).ready(function() {
            $("button#btnPrev").click(function(e){ // previous
                e.preventDefault();
                e.stopPropagation();
                var theForm = $("form#navigation");
                theForm.prop("action", "sales.jsp");
                theForm.submit();
            });
        });//doc ready
    </script>
</body>
</html>