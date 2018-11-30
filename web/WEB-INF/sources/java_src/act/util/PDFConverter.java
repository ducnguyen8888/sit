package act.util;
import  java.io.*;
import java.nio.charset.Charset;
import java.nio.file.*;

/**
 * Created by Duc.Nguyen on 11/9/2018.
 */
public class PDFConverter {


    public static void main(String [] args){
        try {


            PDFConverter.convertToPdf("C:/Users/Duc.Nguyen/IdeaProjects/sit/out/artifacts/sit_war_exploded/temp/","","temp","Hello Duc","http://localhost:4430");

        } catch (Exception e){
            System.out.println(e.toString());
        }
    }

    public PDFConverter(){}


    public static PDFConverter initialContext(){ return new PDFConverter(); }

    public PDFConverter setTempDirectory( String tempDirectory ){
        this.tempDirectory = tempDirectory;
        return this;
    }

    public PDFConverter setRootPath( String rootPath ) {
        this.rootPath = rootPath;
        return this;
    }

    public PDFConverter setFileName( String fileName ) {
        this.fileName = "SIT_"+fileName;
        return this;
    }

    public PDFConverter setUrl( String pdfConverterUrl ) {
        this.pdfConverterUrl = pdfConverterUrl+"/convert2PDF.php";
        return this;
    }


    public PDFConverter initializeHtml( String data ) throws  IOException {
        try (
                BufferedWriter writer = Files.newBufferedWriter(Paths.get(tempDirectory + fileName +".html"), Charset.forName("UTF-8"));
            ){
                writer.write( data );
                //Runtime.getRuntime().exec(rootPath + tempDirectory + fileName+".html" );

        } catch (Exception e) {
            throw  e;
        }

        return this;

    }

    public  static PDFConverter convertToPdf(String rootPath,
                                                    String tempDirectory,
                                                    String fileName,
                                                    String htmlString,
                                                    String pdfConverterUrl
                                                ) throws  Exception {
        try {
            return initialContext().setRootPath(rootPath)
                                    .setTempDirectory(tempDirectory)
                                    .setFileName(fileName)
                                    .setUrl(pdfConverterUrl)
                                    .initializeHtml(htmlString)
                                    .convertToPdf();
        } catch ( Exception e ) {
            throw  e;
        }
    }

    public PDFConverter convertToPdf() throws Exception{
        try {
            java.net.URL obj = new java.net.URL(pdfConverterUrl);
            java.net.HttpURLConnection con = (java.net.HttpURLConnection) obj.openConnection();
            return convertToPdf(con);
        } catch (Exception e){
            throw  e;
        }
    }

    public PDFConverter convertToPdf( java.net.HttpURLConnection con) throws Exception{
        String USER_AGENT = "Mozilla/5.0";
        try ( AutoCloseable conc = ()-> con.disconnect(); ){
            con.setRequestMethod("POST");
            con.setRequestProperty("User-Agent", USER_AGENT);
            con.setRequestProperty("Accept-Language", "en-US,en;q=0.5");
            con.setDoOutput(true);

            String urlParameter = "file="+fileName;

            try ( DataOutputStream wr = new DataOutputStream( con.getOutputStream() ); ){
                wr.writeBytes(urlParameter);
                wr.flush();
                wr.close();

            } catch ( Exception e ){
                throw e;
            }

            pdfResponse = con.getResponseCode();
            if ( pdfResponse >= 400 ) throw new Exception("Failed to convert to PDF");

        } catch ( Exception e){
            throw  e;
        }

        return this;

    }


    public String tempDirectory         = null;
    public String fileName              = null;
    public String pdfConverterUrl       = null;
    public String rootPath              = null;
    public int    pdfResponse           = 0;
}
