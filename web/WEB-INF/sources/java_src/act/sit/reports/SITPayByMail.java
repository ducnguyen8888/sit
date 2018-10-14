package act.sit.reports;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class SITPayByMail extends Report {
    public SITPayByMail() {
        super();
        this.outputFilenamePrefix = "sitpbm_";
    }
    public SITPayByMail(String clientId, String tid) {
        this();
        this.setTransaction(clientId, tid);
    }

    public static Report initialContext(String clientId, String tid) {
        return new SITPayByMail(clientId, tid);
    }

    public  String      clientId        = null;
    public  String      tid             = null;

    public  String      reportName      = "sit_paymt_form";


    public Report setTransaction(String clientId, String tid) {
        this.clientId = clientId;
        this.tid = tid;
        return this;
    }
    public Report setReport(String reportName) {
        this.reportName = reportName;
        return this;
    }

    public  static final Exception   InvalidTransactionException     = new Exception("Failed to locate transaction");

    public String generateParameterString(Connection con) throws Exception {
        StringBuilder builder = new StringBuilder();


        // Verify that the transaction is valid
        try ( PreparedStatement ps = con.prepareStatement("select count(*) from sit_epay where client_id=? and tid=?"); )
        {
            ps.setString(1, clientId);
            ps.setString(2, tid);

            try ( ResultSet rs = ps.executeQuery(); ){    
                rs.next();
                if ( rs.getInt(1) == 0 )
                {
                    throw InvalidTransactionException;
                }
            }
        } catch (Exception exception) {
            executionException = exception;
            throw exception;
        }


        builder.append(String.format("REPORT=%s",reportName));

        builder.append("&P_WEB_CALL='Y'");
        builder.append(String.format("&P_CLIENT_ID=%s&P_TID=%s",
                                     clientId, tid
                                     )
                       );

        return builder.toString();
    }
/*
 * 
Parameters
        reportServer
        http://%appServer%/reports/rwservlet?
        SERVER=%reportServer%
        &USERID=act_inq/texas1
        &DESTYPE=file&DESFORMAT=PDF&DESNAME=%outputFilepath%
        &REPORT=%reportName%
        &P_WEB_CALL='Y'

        &P_CLIENT_ID=%clientId%&P_TID=%tid%
 */
}
