package act.sit;

public class Payment {
  public String can;
    public String year;
    public String month;
    public String description;
    public String amountDue;
    public String amountPending;
    public String paymentAmount;
    public String minPayment;
    public String maxPayment;
    public String reportSeq;
    public int width = 8; // just in case. How many variables are in this class
            
    public Payment(){ }
    public Payment(String can, String reportSeq, String year, String month, String description, String amountDue, String amountPending, String paymentAmount, String minPayment, String maxPayment) {
        this.can = can;
        this.reportSeq = reportSeq;
        this.year = year;
        this.month = month;
        this.description = description;
        this.amountDue = amountDue;
        this.amountPending = amountPending;
        this.paymentAmount = paymentAmount;
        this.minPayment = minPayment;
        this.maxPayment = maxPayment;
    }

    public String getCan() { return can; }
    public String getReportSeq() { return reportSeq; }
    public String getYear() { return year; }
    public String getMonth() { return month; }
    public String getDescription() { return description; }
    public String getAmountDue() { return amountDue; }
    public String getAmountPending() { return amountPending; }
    public String getPaymentAmount() { return paymentAmount; }
    public String getMinPayment() { return minPayment; }
    public String getMaxPayment() {  return maxPayment; }

    public void setCan(String can) { this.can = can; }
    public void setReportSeq(String reportSeq) { this.reportSeq = reportSeq; }
    public void setYear(String year) { this.year = year; }
    public void setMonth(String month) { this.month = month; }
    public void setDescription(String description) { this.description = description; }
    public void setAmountDue(String amountDue) { this.amountDue = amountDue; }
    public void setAmountPending(String amountPending) { this.amountPending = amountPending; }
    public void setPaymentAmount(String paymentAmount) { this.paymentAmount = paymentAmount; }
    public void setMinPayment(String minPayment) { this.minPayment = minPayment; }
    public void setMaxPayment(String maxPayment) { this.maxPayment = maxPayment; }



    @Override
    public String toString() {
        return "Payment{" + "can=" + can + ", year=" + year + ", month=" + month + ", description=" + description + ", amountDue=" + amountDue + ", amountPending=" + amountPending + ", paymentAmount=" + paymentAmount + ", minPayment=" + minPayment + ", maxPayment=" + maxPayment + "}\r\n";
    }

}
