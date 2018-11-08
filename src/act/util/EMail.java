package act.util;

import java.util.Date;
import java.util.*;
import java.util.Properties;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;

import javax.mail.BodyPart;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

/**Sends a text or HTML formatted email.
 *
 * <p>
 * HTML Formatted Messages<br>
 * Images may be included in HTML formatted messages from either external sources,
 * by using an external URL in the <img> tag, or by embedding the image with the email.
 * <p>
 * In the HTML text the images are defined/linked through the src attribute of the <img> tag.
 * External images are included by specifying the entire HTTP url to the image like:
 * <pre>
 *         <img src="http://www.google.com/test-image.jpg">
 * </pre>
 * <p>
 * Images may also be embedded within the message by specifying an image ID within the <img> tag
 * (prefixed with "cid:") and including the image as an attachment to the email:
 * <pre>
 *         <img src="cid:imageID">
 * </pre>
 * <p>
 * Each image will have a unique ID for each different image. If two images referenced in the
 * html text have the same ID then the same image is used for both.
 * <p>
 * In this example the image ID is "imageID".
 * <pre>
 *      <img src="cid:imageID">
 * </pre>
 * <p>
 * The image attachment is "linked" through the attachment Content-ID header.
 * The Java code used to add the referenced image is:
 * <pre>
 *      messageBodyPart = new MimeBodyPart();
 *      DataSource fds = new FileDataSource(img);
 *      messageBodyPart.setDataHandler(new DataHandler(fds));
 *      messageBodyPart.setHeader("Content-ID","<imageID>");
 *      multipart.addBodyPart(messageBodyPart);
 * </pre>
 *
 * <p>
 * Coding Examples:<br>
 * <pre>
 *		<strong> Send simple text message </strong>
 *		EMail.send(from, to,
 *					"Test text email",
 *					"This is a test email sending a text formatted message");
 *
 *		<strong> Send text message with attachments defined in java.util.Map </strong>
 *		Map mapAttachments = new Hashtable();
 *		mapAttachments.put("File1.txt", "This is the first attachment");
 *		mapAttachments.put("File2.txt", "This is the second attachment");
 *		EMail.send(from, to,
 *					"Test text email with text attachments",
 *					"This is a test email sending a text formatted message with java.util.Map based attachments",
 *					mapAttachments);
 *
 *		<strong> Send text message with attachments defined using EMail_Attachments </strong>
 *		EMail_Attachments attachments = new EMail_Attachments();
 *		attachments.addTextAttachment("Testfile1.txt", "This is the first attachment, added as text");
 *		attachments.addFileAttachment("test.png", "D:/a.png");
 *		EMail.send(from, to,
 *					"Test text email with text and file attachments",
 *					"This is a test email sending a text formatted message with EMail_Attachment based attachments",
 *					attachments);
 *
 *		<strong> Send simple html message </strong>
 *		EMail.sendHtml(from, to,
 *					"Test HTML email",
 *					"This is a test email sending a <strong><em>HTML</em></strong> formatted message");
 *
 *		<strong> Send html message with attachments defined using EMail_Images </strong>
 *		EMail_Images htmlMsgImages = new EMail_Images();
 *		htmlMsgImages.addImage("image1", "D:/a.png");
 *		htmlMsgImages.addImage("image2", "D:/b.png");
 *		EMail.sendHtml(from, to,
 *					"Test HTML email with embedded images",
 *					"This is a test email sending a "
 *						+ "<strong><em>HTML</em></strong> formatted message with multiple images<br/>"
 *						+ "<img src=\"cid:image1\"><img src=\"cid:image1\"><img src=\"cid:image2\">",
 *					htmlMsgImages); 
 *
 *		<strong> Send html message with attachments defined using EMail_Attachments </strong>
 *		EMail.sendHtml(from, to,
 *					"Test HTML email with file attachments",
 *					"This is a test email sending a "
 *						+ "<strong><em>HTML</em></strong> formatted message with some file attachments<br/>",
 *					attachments);
 *
 *		<strong> Send html message with attachments defined using EMail_Images and EMail_Attachments </strong>
 *		EMail.sendHtml(from, to,
 *					"Test HTML email with embedded images and file attachments",
 *					"This is a test email sending a "
 *						+ "<strong><em>HTML</em></strong> formatted message with multiple images and some other file attachments<br/>"
 *						+ "<img src=\"cid:image1\"><img src=\"cid:image1\"><img src=\"cid:image2\">",
 *					htmlMsgImages,attachments);
 * </pre>
 */
public class EMail {
	/** The IP address of the SMTP server used to send emails */
	public static final String SMTPHost = "192.168.7.1";

	public void test() throws Exception {
		test("email.test@lgbs.com","scott.shike@lgbs.com","D:/a.png");
	}
	public void test(String from, String to, String filesystemImage) throws Exception {

		// Send simple text message
		try {
			EMail.send(from, to,
				"Test text email",
				"This is a test email sending a text formatted message");
		} catch (Exception e) {
			EMail.extend(e,"Text Message");
		}

		// Send text message with attachments defined in java.util.Map
		try {
			Map mapAttachments = new Hashtable();
			mapAttachments.put("File1.txt", "This is the first attachment");
			mapAttachments.put("File2.txt", "This is the second attachment");
			EMail.send(from, to,
						"Test text email with text attachments",
						"This is a test email sending a text formatted message with java.util.Map based attachments",
						mapAttachments);
		} catch (Exception e) {
			EMail.extend(e,"Text Message with text attachments");
		}


		// Send text message with attachments defined using EMail_Attachments
		try {
			EMail_Attachments attachments = new EMail_Attachments();
			attachments.addTextAttachment("Testfile1.txt", "This is the first attachment, added as text");
			attachments.addFileAttachment("test.png", filesystemImage);
			EMail.send(from, to,
						"Test text email with text and file attachments",
						"This is a test email sending a text formatted message with EMail_Attachment based attachments",
						attachments);
		} catch (Exception e) {
			EMail.extend(e,"Text Message with EMail_Attachments attachments");
		}


		// Send simple html message
		try {
			EMail.sendHtml(from, to,
							"Test HTML email",
							"This is a test email sending a <strong><em>HTML</em></strong> formatted message");
		} catch (Exception e) {
			EMail.extend(e,"HTML Message");
		}


		// Send html message with attachments defined using EMail_Images
		try {
			EMail_Images htmlMsgImages = new EMail_Images();
			htmlMsgImages.addImage("image1", filesystemImage);
			htmlMsgImages.addImage("image2", filesystemImage);

			EMail.sendHtml(from, to,
							"Test HTML email with embedded images",
							"This is a test email sending a "
							+ "<strong><em>HTML</em></strong> formatted message with multiple images<br/>"
							+ "<img src=\"cid:image1\"><img src=\"cid:image1\"><img src=\"cid:image2\">",
							htmlMsgImages);
		} catch (Exception e) {
			EMail.extend(e,"HTML Message with embedded EMail_Images images");
		}

		// Send html message with attachments defined using EMail_Attachments
		try {
			EMail_Attachments attachments = new EMail_Attachments();
			attachments.addTextAttachment("Testfile1.txt", "This is the first attachment, added as text");
			attachments.addFileAttachment("test.png", "D:/a.png");

			EMail.sendHtml(from, to,
							"Test HTML email with file attachments",
							"This is a test email sending a "
							+ "<strong><em>HTML</em></strong> formatted message with some file attachments<br/>",
							attachments);
		} catch (Exception e) {
			EMail.extend(e,"HTML Message with EMail_Attachments attachments");
		}

		// Send html message with attachments defined using EMail_Images and EMail_Attachments
		try {
			EMail_Images htmlMsgImages = new EMail_Images();
			htmlMsgImages.addImage("image1", "D:/a.png");
			htmlMsgImages.addImage("image2", "D:/b.png");

		    EMail_Attachments attachments = new EMail_Attachments();
		    attachments.addTextAttachment("Testfile1.txt", "This is the first attachment, added as text");
		    attachments.addFileAttachment("test.png", "D:/a.png");

			EMail.sendHtml(from, to,
							"Test HTML email with embedded images and file attachments",
							"This is a test email sending a "
							+ "<strong><em>HTML</em></strong> formatted message with multiple images and some other file attachments<br/>"
							+ "<img src=\"cid:image1\"><img src=\"cid:image1\"><img src=\"cid:image2\">",
							htmlMsgImages,attachments);
		} catch (Exception e) {
			EMail.extend(e,"HTML Message with embedded EMail_Images images and EMail_Attachments attachments");
		}

		return;
	}


	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String subject, String textMessage) throws Exception {
		sendEmail("text/plain",from,to,null,null,subject,textMessage,null,null,null);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String subject, String textMessage) throws Exception {
		sendEmail("text/plain",from,to,cc,null,subject,textMessage,null,null,null);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String bcc, String subject, String textMessage) throws Exception {
		sendEmail("text/plain",from,to,cc,bcc,subject,textMessage,null,null,null);
	}


	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param textAttachemnts any text format attachments to add to the email, Map key is the file name and value is the file content
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String subject, String textMessage, Map textAttachments) throws Exception {
		sendEmail("text/plain",from,to,null,null,subject,textMessage,textAttachments,null,null);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param textAttachemnts any text format attachments to add to the email, Map key is the file name and value is the file content
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String subject, String textMessage, Map textAttachments) throws Exception {
		sendEmail("text/plain",from,to,cc,null,subject,textMessage,textAttachments,null,null);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param textAttachemnts any text format attachments to add to the email, Map key is the file name and value is the file content
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String bcc, String subject, String textMessage, Map textAttachments) throws Exception {
		sendEmail("text/plain",from,to,cc,bcc,subject,textMessage,textAttachments,null,null);
	}


	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String subject, String textMessage, EMail_Attachments attachments) throws Exception {
		sendEmail("text/plain",from,to,null,null,subject,textMessage,null,null,attachments);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String subject, String textMessage, EMail_Attachments attachments) throws Exception {
		sendEmail("text/plain",from,to,cc,null,subject,textMessage,null,null,attachments);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String bcc, String subject, String textMessage, EMail_Attachments attachments) throws Exception {
		sendEmail("text/plain",from,to,cc,bcc,subject,textMessage,null,null,attachments);
	}


	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param textAttachemnts any text format attachments to add to the email, Map key is the file name and value is the file content
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String subject, String textMessage, Map textAttachments, EMail_Attachments attachments) throws Exception {
		sendEmail("text/plain",from,to,null,null,subject,textMessage,textAttachments,null,attachments);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param textAttachemnts any text format attachments to add to the email, Map key is the file name and value is the file content
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String subject, String textMessage, Map textAttachments, EMail_Attachments attachments) throws Exception {
		sendEmail("text/plain",from,to,cc,null,subject,textMessage,textAttachments,null,attachments);
	}
	/**Sends a simple text formatted EMail message (text/plain).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param textMessage the email content/body
	 * @param textAttachemnts any text format attachments to add to the email, Map key is the file name and value is the file content
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void send(String from, String to, String cc, String bcc, String subject, String textMessage, Map textAttachments, EMail_Attachments attachments) throws Exception {
		sendEmail("text/plain",from,to,cc,bcc,subject,textMessage,textAttachments,null,attachments);
	}



	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String subject, String htmlMessage) throws Exception {
		sendEmail("text/html",from,to,null,null,subject,htmlMessage,null,null,null);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String subject, String htmlMessage) throws Exception {
		sendEmail("text/html",from,to,cc,null,subject,htmlMessage,null,null,null);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String bcc, String subject, String htmlMessage) throws Exception {
		sendEmail("text/html",from,to,cc,bcc,subject,htmlMessage,null,null,null);
	}



	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param images  any images that are included in image tags of the email body/content
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String subject, String htmlMessage, EMail_Images images) throws Exception {
	        sendEmail("text/html",from,to,null,null,subject,htmlMessage,null,images,null);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param images  any images that are included in image tags of the email body/content
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String subject, String htmlMessage, EMail_Images images) throws Exception {
	        sendEmail("text/html",from,to,cc,null,subject,htmlMessage,null,images,null);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param images  any images that are included in image tags of the email body/content
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String bcc, String subject, String htmlMessage, EMail_Images images) throws Exception {
	        sendEmail("text/html",from,to,cc,bcc,subject,htmlMessage,null,images,null);
	}


	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String subject, String htmlMessage, EMail_Attachments attachments) throws Exception {
	        sendEmail("text/html",from,to,null,null,subject,htmlMessage,null,null,attachments);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String subject, String htmlMessage, EMail_Attachments attachments) throws Exception {
	        sendEmail("text/html",from,to,cc,null,subject,htmlMessage,null,null,attachments);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String bcc, String subject, String htmlMessage, EMail_Attachments attachments) throws Exception {
	        sendEmail("text/html",from,to,cc,bcc,subject,htmlMessage,null,null,attachments);
	}


	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param images  any images that are included in image tags of the email body/content
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String subject, String htmlMessage, EMail_Images images, EMail_Attachments attachments) throws Exception {
	        sendEmail("text/html",from,to,null,null,subject,htmlMessage,null,images,attachments);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param images  any images that are included in image tags of the email body/content
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String subject, String htmlMessage, EMail_Images images, EMail_Attachments attachments) throws Exception {
	        sendEmail("text/html",from,to,cc,null,subject,htmlMessage,null,images,attachments);
	}
	/**Sends a HTML formatted EMail message (text/html).
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param htmlMessage the html formatted email content/body
	 * @param images  any images that are included in image tags of the email body/content
	 * @param attachments any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendHtml(String from, String to, String cc, String bcc, String subject, String htmlMessage, 
								EMail_Images images, EMail_Attachments attachments) throws Exception {
		sendEmail("text/html",from,to,cc,bcc,subject,htmlMessage,null,images,attachments);
	}


	/**Sends an EMail message.
	 * @param type    the email format, typically either "text/plain" or "text/html"
	 * @param from    the "from" address of the email
	 * @param to      the "to" addresses of the email, separate multiple addresses with ";"
	 * @param cc      the "cc" addresses of the email, separate multiple addresses with ";"
	 * @param bcc     the "bcc" addresses of the email, separate multiple addresses with ";"
	 * @param subject the email subject line
	 * @param body    the email content/body
	 * @param textAttachemnts any text format attachments to add to the email, Map key is the filename and value is the file content
	 * @param images  any images that are included in image tags of an HTML format email body/content
	 * @param attachmnts any file attachments to add to the email
	 * @throws Exception if an error occurs building or sending the email
	 */
	public static void sendEmail(String type, String from, String to, String cc, String bcc, String subject, String body, 
								 Map textAttachments, EMail_Images images, EMail_Attachments attachments) throws Exception {
		try {
			Properties props = new Properties();
			props.put("mail.smtp.host", SMTPHost);
			// The following timeout properties may not be available until Java 1.5
			props.put("mail.smtp.connectiontimeout","5000"); // Socket connection timeout value in milliseconds
			props.put("mail.smtp.timeout","5000");           // Socket read timeout value in milliseconds
			props.put("mail.smtp.writetimeout","6000");      // Socket write timeout value in milliseconds
			Session session = Session.getDefaultInstance(props, null);

			MimeMessage message = new MimeMessage(session);
			message.setFrom(new InternetAddress(from));
		        String [] receipients = to.split(";");
		        for ( int i=0; i < receipients.length; i++ ) 
		                message.addRecipient(Message.RecipientType.TO,new InternetAddress(receipients[i]));
		        if ( cc != null ) {
		                receipients = cc.split(";");
		                for ( int i=0; i < receipients.length; i++ ) 
		                message.addRecipient(Message.RecipientType.CC,new InternetAddress(receipients[i]));
		        }
		        if ( bcc != null ) {
		                receipients = bcc.split(";");
		                for ( int i=0; i < receipients.length; i++ ) 
		                message.addRecipient(Message.RecipientType.BCC,new InternetAddress(receipients[i]));
		        }
			message.setSubject(subject);


			MimeMultipart multipart = new MimeMultipart("related");

			BodyPart messageBodyPart = new MimeBodyPart();
			messageBodyPart.setContent(body, type);
			multipart.addBodyPart(messageBodyPart);

		        if ( textAttachments != null ) {
		                String [] names = (String []) textAttachments.keySet().toArray(new String[0]);
		                Arrays.sort(names);
		                for ( int i=0; i < names.length; i++ ) {
		                        messageBodyPart = new MimeBodyPart();
		                        messageBodyPart.setFileName(names[i]);
		                        messageBodyPart.setText((String)textAttachments.get(names[i]));
		                        multipart.addBodyPart(messageBodyPart);
		                }
		        }

			if ( images != null && images.hasImages() ) {
				images.addImages(multipart);
			}
		        if ( attachments != null && attachments.hasAttachments() ) {
		                attachments.addAttachments(multipart);
		        }

			message.setContent(multipart);

			Transport.send(message);
		} catch (Exception e) {
			extend(e,"Sending email");
		}
	}


	/** Throws a new exception of the same type with the provided message prefixed to the existing exception message.
	 *  <p>
	 *  A new exception is created of the same type as the specified exception. The exception message remains the
	 *  same but is prefixed by the user specified message. Useful to provide code location information in an exception.
	 *  <p>
	 *  Calling this function throws the new exception, it does not return the exception object.
     * @param e Exception to extend
	 * @param message message to prefix to existing exception message
	 * @throws Exception newly created exception of the same class type with the same exception message prefixed by the specified message
	 */
	private static void extend(Exception e, String message) throws Exception {
		throw (Exception) e.getClass().getConstructor(new Class[]{(new String()).getClass()}).newInstance((Object[])(new String[]{message + ". " + e.getMessage()}));
	}

}
