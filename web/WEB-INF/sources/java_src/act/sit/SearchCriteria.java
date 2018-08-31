package act.sit;

/**
 * Created by Duc.Nguyen on 8/30/2018.
 */
public class SearchCriteria {
    public SearchCriteria(){}
    public SearchCriteria(String dealerNo,
                          String dealerName,
                          String dealerAddress,
                          String userName,
                          String userId )  {
        this.dealerNo       = dealerNo;
        this.dealerName     = dealerName;
        this.dealerAddress  = dealerAddress;
        this.userName       = userName;
        this.userId         = userId;
    }

    public String dealerNo      = null;
    public String dealerName    = null;
    public String dealerAddress = null;
    public String userName      = null;
    public String userId        = null;
}
