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

/** Stores file system files and text data to be used as file attachments to an Email
*/
public class EMail_Attachments {
	public EMail_Attachments() {
		super();
	}

	/**The internal store of file attachments created */
	private Hashtable attachments = new Hashtable();


	/**Removes all created attachments
	 */
	public void clear() { if ( attachments != null ) attachments.clear(); }

	/**Removes all created attachments
	 */
	public void finalize() { if ( attachments != null ) attachments.clear(); }

	/**Returns whether any attachments have been defined or not.
	 * @return true if any attachments have been defined, false otherwise
	 */
	public boolean hasAttachments() {
		return (attachments != null && attachments.size() > 0);
	}

	/**Adds the defined attachments to the specified email message
	 * @param message the email message to add the attachments to
	 * @throws MessagingException if an error occurs adding an attachment as a message BodyPart
	 */
	public void addAttachments(MimeMultipart message) throws MessagingException {
		String [] keys = (String []) attachments.keySet().toArray(new String[0]);
		Arrays.sort(keys);
		for ( int i=0; i < keys.length; i++ ) {
			message.addBodyPart((BodyPart)attachments.get(keys[i]));
		}
	}


	/**Adds a file system file as an attachment, the file name is used as the attachment file name.
	 * @param filepath the file system path to the file, includes filename
	 * @throws MessagingException if an error occurs retrieving the file or adding it to the internal store
	 */
	public void addFileAttachment(String filepath) throws MessagingException {
		String name = filepath.substring(filepath.replaceAll("\\\\","/").lastIndexOf('/')+1);
		attachments.put(name,createFileAttachment(name,filepath));
	}
	/**Adds a file system file as an attachment, the specified file name is used as the attachment file name.
	 * @param name     the attachment file name to use
	 * @param filepath the file system path to the file
	 * @throws MessagingException if an error occurs retrieving the file or adding it to the internal store
	 */
	public void addFileAttachment(String name, String filepath) throws MessagingException {
		attachments.put(name,createFileAttachment(name,filepath));
	}
	/**Adds the specified text String as a file attachment, the specified file name is used as the attachment file name.
	 * @param name     the attachment file name to use
	 * @param text     the text string to add as a file
	 * @throws MessagingException if an error occurs retrieving the file or adding it to the internal store
	 */
	public void addTextAttachment(String name, String text) throws MessagingException {
		attachments.put(name,createTextAttachment(name,text));
	}

	/**Creates a BodyPart object from a file system file, the specified name is used as the attachment file name
	 * @param name     the attachment file name to use
	 * @param filepath the file system path to the file, includes filename
	 * @throws MessagingException if an error occurs creating the BodyPart object
	 */
	public static BodyPart createFileAttachment(String name, String filepath) throws MessagingException {
		BodyPart messageBodyPart = new MimeBodyPart();
		DataSource source = new FileDataSource(filepath);
		messageBodyPart.setFileName(name);
	        messageBodyPart.setDataHandler(new DataHandler(source));

		return messageBodyPart;
	}
	/**Creates a BodyPart object from a text String, the specified name is used as the attachment file name
	 * @param name     the attachment file name to use
	 * @param text     the text string to create the BodyPart object from
	 * @throws MessagingException if an error occurs creating the BodyPart object
	 */
	public static BodyPart createTextAttachment(String name, String text) throws MessagingException {
		BodyPart messageBodyPart = new MimeBodyPart();
		messageBodyPart.setFileName(name);
		messageBodyPart.setText(text);

		return messageBodyPart;
	}
}
