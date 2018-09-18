package act.sit;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class Payments {
    public ArrayList<Payment> payments;
    public String hashcode;
    public String user;
    public String username;
    public String client;
    public String client_id;

    public Payments() {
        this.payments = new ArrayList<Payment>();
        this.hashcode = "";
        this.user = "";
        this.username = "";
        this.client = "";
        this.client_id = "";
    }

    public Payments(String hashcode, String user, String username,
                    String client_id, String client) {
        this.payments = new ArrayList<Payment>();
        this.hashcode = hashcode;
        this.user = user;
        this.username = username;
        this.client = client;
        this.client_id = client_id;
    }

    public void add(Payment info) {
        this.payments.add(info);
        Collections.sort(this.payments,
                         new PaymentChainedComparator(new PaymentCanComparator(),
                                                      new PaymentYearComparator(),
                                                      new PaymentMonthComparator()));
    }

    public void remove(String can, String year, String month) {
        month = (month.length() == 1) ? "0" + month : month;
        for (Payment payment : this.payments) {
            if (can.equals(payment.getCan()) &&
                year.equals(payment.getYear()) &&
                month.equals(payment.getMonth())) {
                this.payments.remove(this.payments.indexOf(payment));
                return;
            }
        }
    }

    public void removeAll() {
        this.payments.clear();
    }

    public int size() {
        return this.payments.size();
    }

    public int getWidth() {
        return this.payments.get(0).width;
    }

    /**
     * @param can
     * @return
     */
    public ArrayList<Payment> getPaymentsForForm(String can) {
        ArrayList<Payment> al = new ArrayList<Payment>();
        for (Payment payment : this.payments) {
            if ((payment.getCan()).equals(can)) {
                al.add(payment);
            }
        }
        return al;

    }

    public String getPayments(String can) {
        StringBuffer sb = new StringBuffer();
        if (this.payments.size() > 0) {
            for (Payment payment : this.payments) {
                if ((payment.getCan()).equals(can)) {
                    sb.append("      {\r\n");
                    sb.append("        \"description\" : \"" + payment.getDescription() + "\",\r\n");
                    sb.append("        \"month\" : \"" + payment.getMonth() + "\",\r\n");
                    sb.append("        \"year\" : \"" + payment.getYear() + "\",\r\n");
                    sb.append("        \"reportSeq\" : \"" + payment.getReportSeq() + "\",\r\n");
                    sb.append("        \"amountDue\" : \"" + payment.getAmountDue() + "\",\r\n");
                    sb.append("        \"amountPending\" : \"" + payment.getAmountPending() + "\",\r\n");
                    sb.append("        \"paymentAmount\" : \"" + payment.getPaymentAmount() + "\",\r\n");
                    sb.append("        \"minPayment\" : \"" + payment.getMinPayment() + "\",\r\n");
                    sb.append("        \"maxPayment\" : \"" + payment.getMaxPayment() + "\"\r\n");
                    sb.append("      },\r\n");
                }
            }
            // cut off end string bits
            sb.setLength(sb.length() - 3);
            sb.append("\r\n    ]\r\n");
            // sb.append("    }, {\r\n");
            return sb.toString();
        } else {
            return "";
        }
    }

    public String getPayments(Dealerships ds) {
        int recordCounter = 0;
        StringBuffer sb = new StringBuffer();
        Dealership d = new Dealership();
        sb.append("{\r\n");
        sb.append("  \"name\": \"" + this.user + "\",\r\n");
        sb.append("  \"username\": \"" + this.username + "\",\r\n");
        sb.append("  \"client\": \"" + this.client + "\",\r\n");
        sb.append("  \"client_id\": \"" + this.client_id + "\",\r\n");
        sb.append("  \"dealers\": [\r\n");

        if (ds.size() > 0) {
            try {
                d = new Dealership();
                for (int i = 0; i < ds.size(); i++) {
                    d = (Dealership)ds.get(i);
                    if (doesExist(d)) {
                        recordCounter++;
                        sb.append("  {\r\n");
                        sb.append("    \"can\" : \"" + d.can + "\",\r\n");
                        sb.append("    \"aprdistacc\" : \"" + d.aprdistacc + "\",\r\n");
                        sb.append("    \"nameline1\" : \"" + d.nameline1 + "\",\r\n");
                        sb.append("    \"nameline2\" : \"" + d.nameline2 + "\",\r\n");
                        sb.append("    \"nameline3\" : \"" + d.nameline3 + "\",\r\n");
                        sb.append("    \"nameline4\" : \"" + d.nameline4 + "\",\r\n");
                        sb.append("    \"city\" : \"" + d.city + "\",\r\n");
                        sb.append("    \"state\" : \"" + d.state + "\",\r\n");
                        sb.append("    \"zipcode\" : \"" + d.zipcode + "\",\r\n");
                        sb.append("    \"payment\" : [\r\n");
                        sb.append(getPayments(d.can));
                        sb.append("  },\r\n");
                    }
                }
                //sb.append("**************Record Count: " + recordCounter + "****************\r\n");
                // cut off end string bits
                if (recordCounter > 0) {
                    sb.setLength(sb.length() - 3);
                    sb.append("]\r\n}");
                } else {
                    sb.setLength(sb.length() - 1);
                    sb.append("]\r\n}");
                }


            } catch (Exception e) {
                return "Exception: " + e.toString();
            }
        }
        return sb.toString();
    }

    public boolean doesExist(Dealership d) {
        for (Payment payment : this.payments) {
            if ((payment.getCan()).equals(d.can))
                return true;
        }
        return false;
    }

    public boolean isInCart(String can, String year, String month) {
        for (Payment payment : this.payments) {
            if ((payment.getCan()).equals(can) &&
                (payment.getYear()).equals(year) &&
                (payment.getMonth()).equals(month))
                return true;
        }
        return false;
    }

    public static void main(String[] args) {
        Payments p =
            new Payments("123456", "Jason Cook", "jcook", "79000000", "Fort Bend County");
        p.add(new Payment("H000001", "1", "2016", "02", "February 2016",
                          "1000.00", "0.0", "1000.00", "1000.00", "0.00"));
        p.add(new Payment("H000001", "2", "2015", "12", "December 2015",
                          "1000.00", "0.0", "1000.00", "1000.00", "0.00"));
        p.add(new Payment("H000003", "1", "2016", "05", "May 2016", "1000.00",
                          "0.0", "1000.00", "1000.00", "0.00"));
        p.add(new Payment("H000001", "1", "2016", "04", "April 2016",
                          "1000.00", "0.0", "1000.00", "1000.00", "0.00"));
        p.add(new Payment("H000002", "1", "2014", "01", "January 2014",
                          "1000.00", "0.0", "1000.00", "1000.00", "0.00"));

        System.out.println("first run:");
        for (Payment str : p.payments) {
            //System.out.println(str);
        }

        p.remove("H00001", "2015", "12");

        System.out.println("second run:");
        for (Payment str : p.payments) {
            //.out.println(str);
        }
        Dealerships ds = new Dealerships();
        ds.add(new Dealership("H000001", "Jason1", "", "", "", "Austin", "TX",
                              "USA", "74128", "9186452810", "2016"));
        ds.add(new Dealership("H000002", "Jason2", "", "", "", "Austin", "TX",
                              "USA", "74128", "9186452810", "2016"));
        ds.add(new Dealership("H000003", "Jason3", "", "", "", "Austin", "TX",
                              "USA", "74128", "9186452810", "2016"));

        System.out.println(p.getPayments(ds));
        //System.out.println("in cart? " + p.isInCart("H000002", "2014", "01"));
        //System.out.println("in cart? " + p.isInCart("H000002", "2014", "02"));
        //ArrayList<Payment> al = p.getPaymentsForForm("H000001");
        //System.out.println("AL is " + al);
        //  System.out.println("p is " + p.get);
        //System.out.println("p is " + p.getPayments("H000001"));
        //System.out.println("p.size() is " + p.size());
        p.removeAll();
        System.out.println("***** cleared cart *****\r\n");
        System.out.println(p.getPayments(ds));

    }


    public static class PaymentChainedComparator implements Comparator<Payment> {
        private List<Comparator<Payment>> listComparators;

        public PaymentChainedComparator(Comparator<Payment>... comparators) {
            this.listComparators = Arrays.asList(comparators);
        }

        @Override
        public int compare(Payment o1, Payment o2) {
            for (Comparator<Payment> comparator : listComparators) {
                int result = comparator.compare(o1, o2);
                if (result != 0) {
                    return result;
                }
            }
            return 0;
        }
    }

    public static class PaymentMonthComparator implements Comparator<Payment> {
        @Override
        public int compare(Payment o1, Payment o2) {
            return o2.getMonth().compareTo(o1.getMonth());
        }
    }

    public static class PaymentYearComparator implements Comparator<Payment> {
        @Override
        public int compare(Payment o1, Payment o2) {
            return o2.getYear().compareTo(o1.getYear());
        }
    }

    public static class PaymentCanComparator implements Comparator<Payment> {
        @Override
        public int compare(Payment o1, Payment o2) {
            return o1.getCan().compareTo(o2.getCan());
        }
    }
}
