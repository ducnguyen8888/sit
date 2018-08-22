package act.util;


import java.util.Arrays;
import java.util.Hashtable;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;

import javax.mail.BodyPart;
import javax.mail.MessagingException;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMultipart;

/**
 * This is for when the image is to be included in the email with the HTML. If an
 * external URL is used as the image source this is not needed.
 * 
 * In the HTML text the images are defined/linked through the src attribute. Each image 
 * will have a unique ID for each different image. If two images referenced in the
 * html text have the same ID then the same image is used for both.
 * 
 * In the example below the image ID is "imageID".
 * 
 * The HTML refers to the image ID in the <img> src attribute prefixed with "cid:"
 * 
 * 	<img src="cid:imageID">
 * 
 * The image attachment is "linked" through the attachment Content-ID header.
 * The Java code used to add the referenced image is:
 * 
 *      messageBodyPart = new MimeBodyPart();
 *	DataSource fds = new FileDataSource(img);
 *	messageBodyPart.setDataHandler(new DataHandler(fds));
 *	messageBodyPart.setHeader("Content-ID","<imageID>");
 *	multipart.addBodyPart(messageBodyPart);
 *
 */
public class EMail_Images {
	public EMail_Images() {
		super();
	}

	/**The internal store of file attachments created */
	private Hashtable images = new Hashtable();

	/**Removes all created attachments
	 */
	public void clear() { if ( images != null ) images.clear(); }
	/**Removes all created attachments
	 */
	public void finalize() { if ( images != null ) images.clear(); }

	/**Returns whether any image attachments have been defined or not.
	 * @return true if any image attachments have been defined, false otherwise
	 */
	public boolean hasImages() { return (images != null && images.size() > 0); }

	/**Adds the defined embedded image attachments to the specified email message
	 * @param message the email message to add the image attachments to
	 * @throws MessagingException if an error occurs adding an attachment as a message BodyPart
	 */
	public void addImages(MimeMultipart message) throws MessagingException {
		String [] keys = (String []) images.keySet().toArray(new String[0]);
		Arrays.sort(keys);
		for ( int i=0; i < keys.length; i++ ) {
			message.addBodyPart((BodyPart)images.get(keys[i]));
		}
	}

	/**Adds a file system file as an embedded image attachment, the file system file name is used
	 * as the image CID or Content-ID.
	 * @param name     the attachment file name to use
	 * @param filepath the file system path to the file
	 * @throws MessagingException if an error occurs retrieving the file or adding it to the internal store
	 */
	public void addImage(String filepath) throws MessagingException {
		String name = filepath.substring(filepath.replaceAll("\\\\","/").lastIndexOf('/')+1);
		images.put(name,createImageAttachment(name,filepath));
	}
	/**Adds a file system file as an embedded image attachment, the specified file name is used
	 * as the image CID or Content-ID.
	 * @param name     the attachment file name to use
	 * @param filepath the file system path to the file
	 * @throws MessagingException if an error occurs retrieving the file or adding it to the internal store
	 */
	public void addImage(String name, String filepath) throws MessagingException {
		images.put(name,createImageAttachment(name,filepath));
	}
	/**Creates a BodyPart object from a file system file used as an embedded image in a HTML email,
	 * the specified name is used as the image CID or Content-ID
	 * @param name     the attachment file name to use
	 * @param filepath the file system path to the file, includes filename
	 * @throws MessagingException if an error occurs creating the BodyPart object
	 */
	public static BodyPart createImageAttachment(String name, String filepath) throws MessagingException {
		BodyPart messageBodyPart = EMail_Attachments.createFileAttachment(name, filepath);
		messageBodyPart.setHeader("Content-ID","<" + name + ">");
		return messageBodyPart;
	}
}
