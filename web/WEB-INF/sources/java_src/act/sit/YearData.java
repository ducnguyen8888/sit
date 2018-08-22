package act.sit;

public class YearData implements Comparable {
    public YearData(int year) {
        this.year = year;
    }

    public  int             year        = 0;
    public  MonthData []    monthData   = null;

    public void add(YearData yearData) {
    }

    public MonthData month(int month) {
        for ( MonthData data : monthData ) {
            if ( data.month == month )  
                return data;
        }

        return null;
    }

    public  int     compareTo(YearData other) {
        return this.year - other.year;
    }

    public int compareTo(Object o) {
        return 0;
    }
}

