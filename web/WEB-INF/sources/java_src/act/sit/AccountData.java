package act.sit;

public class AccountData implements Comparable {
    public AccountData(String can) {
        this.can = can;
    }

    public  String      can         = null;
    public  YearData [] yearData    = null;

    public void add(YearData yearData) {
    }

    public YearData year(int year) {
        for ( YearData data : yearData ) {
            if ( data.year == year )
                return data;
        }

        return null;
    }


    public  int     compareTo(AccountData other) {
        return this.can.compareTo(other.can);
    }

    public int compareTo(Object o) {
        return 0;
    }
}

