package act.util;
import  java.io.*;
/**
 * Created by Duc.Nguyen on 11/9/2018.
 */
public class PDFConverter {
    public static void main(String [] args){
        try {
            String USER_AGENT = "Mozilla/5.0";
            java.net.URL obj = new java.net.URL("http://localhost:4430/convert2PDF.php");
            java.net.HttpURLConnection con = (java.net.HttpURLConnection) obj.openConnection();
            con.setRequestMethod("POST");
            con.setRequestProperty("User-Agent", USER_AGENT);
            con.setRequestProperty("Accept-Language", "en-US,en;q=0.5");
            con.setDoOutput(true);
            DataOutputStream wr = new DataOutputStream(con.getOutputStream());
            String urlParameters = "file=SIT_11092018153128";
            wr.writeBytes(urlParameters);
            wr.flush();
            wr.close();

            int responseCode = con.getResponseCode();

            System.out.println( responseCode );

        } catch (Exception e){
            System.out.println(e.toString());
        }
    }
}
