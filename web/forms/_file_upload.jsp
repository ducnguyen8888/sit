<%@ include file="../_configuration.inc" %><%
	response.addHeader("Pragma" , "No-cache") ;
	response.addHeader("Cache-Control", "no-cache") ;
	response.addDateHeader("Expires", 0); 

byte LF   = '\r';
	byte EOL  = '\n';

	int  sidx = 0, cidx = 0, eidx = 0; // Used to walk through the content data
	int  idx  = 0; // Simple string search index

	boolean isFile      = false,
	        wasUploaded = false;

	byte [] requestData = null;
	String boundary = null;
	String endBoundary = null;


	boolean isFileUpload = "Y".equals(request.getParameter("upload"));

	String filename  = null,
	       paramname = null;

	String user_message = null;
String cmpString = null;

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
				out.print("Verifying request" + e);
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
				out.print("Reading request data" + e);
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
					String contentDisposition = new String(requestData,sidx,eidx-sidx); //Content-Disposition: form-data; name="year"

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
						String contentType = new String(requestData,sidx,eidx-sidx);//Content-Type: application/pdf
						if ( ! contentType.startsWith("Content-Type: ") )
							throw new InstantiationException("Data error. Failed to find content type for " + filename);
						contentType = contentType.substring(14);
					} else {
						idx = contentDisposition.indexOf("; name=");
						paramname = contentDisposition.substring(idx+8,contentDisposition.length()-1);//bizStart
					}
					sidx = cidx = eidx += 4; // skip past end of current line and following blank line


					// Determine the bounds of our data by locating the next boundary marker
					
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


						//out.print("requestData is " + requestData + "<br>");
						//out.print("sidx is " + sidx + "<br>");
						//out.print("cidx-sidx is " + (cidx-sidx) + "<br>");
						long millis = System.currentTimeMillis() / 1000;
						String addl_file_name = "SIT_ADDL_" + millis + ".pdf";
						InputStream inputStream = null;
						OutputStream outputStream = null;
						// read this file into InputStream
						inputStream = new DataInputStream(request.getInputStream());
						// write the inputStream to a FileOutputStream
						outputStream = new FileOutputStream(new File(tempDirectory + addl_file_name));//tempDirectory = "/usr2/webtemp/";
						int read = 0;
						byte[] bytes = new byte[1024];
						while ((read = inputStream.read(requestData)) != -1) {
							outputStream.write(requestData, 0, read);
						}
						outputStream.flush();
						outputStream.close();
						Runtime.getRuntime().exec( "/usr/bin/chmod 666 " + tempDirectory + addl_file_name );


						//uploadFile(datasource,prc_user,prc_pswd,prc_number,filename,requestData,sidx,cidx-sidx);
						//wasUploaded = true;
						//break;
					}

					sidx = eidx+2; // Move past the end of the current line
				}
			} catch (Exception e) {
				out.print("Processing request data" + e);
			}


			if ( ! wasUploaded )
				throw new InstantiationException("Data error. No file data. File may not have been specified.");

		} catch (Exception e) {
			user_message = e.toString();
		}
	}

	String contentType = request.getContentType();
	boolean itWorked = false;
	if ((contentType != null) && (contentType.indexOf("multipart/form-data") >= 0)) {

		itWorked = true;
	} else {
		itWorked = false;
	}
%>
