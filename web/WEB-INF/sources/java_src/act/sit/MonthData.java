package act.sit;

public class MonthData implements Comparable {

  public int month = 0;
  public double amountX = 0.0;
  public double amountY = 0.0;
  public double amountZ = 0.0;


    public MonthData(int month, double amountX, double amountY,
                     double amountZ) {
        this.month = month;
        this.amountX = amountX;
        this.amountY = amountY;
        this.amountZ = amountZ;
    }

    public static String[] monthNames =
        new String[] { "Unspecified", "January", "February", "March", "April",
                       "May", "June", "July", "August", "September", "October",
                       "November", "December" };

    public String month() {
        if (month < 0 || month > 12)
            return "Invalid Month: " + month;
        return monthNames[month];
    }


    public int compareTo(MonthData other) {
        return this.month - other.month;
    }

    public int compareTo(Object o) {
        return 0;
    }
}
