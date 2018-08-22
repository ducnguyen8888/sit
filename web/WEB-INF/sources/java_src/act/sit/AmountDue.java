package act.sit;


import act.util.Connect;

import java.math.BigDecimal;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;

import java.sql.SQLException;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;

import java.time.LocalDate;
import java.time.Year;
import java.time.YearMonth;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Hashtable;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;


public class AmountDue implements Comparable
{
    public AmountDue()
    {
    }

    public AmountDue(String clientId, String can)
    {
        this.clientId       = clientId;
        this.can            = can;
    }

    public AmountDue(String clientId, String can, String year)
    {
        this.clientId       = clientId;
        this.can            = can;
        this.year           = year;
    }

    public AmountDue(String clientId, String can, String year, String month)
    {
        this.clientId       = clientId;
        this.can            = can;
        this.year           = year;
        this.month          = String.format("%02d",Integer.parseInt(month));

        this.id = String.format("%s%s", year, month);
    }


    public static void main(String... args) throws Exception
    {
        String can = "1234";

        AmountDue[] due = getDue("jdbc/sit", "7580","99B03144000000000");
        //for ( AmountDue e : due )
        //{
        //    System.out.println(e.toString());
        //}
        System.out.println(showRecords(due));
    }



    public static AmountDue[] getDue(String datasource, String clientId, String can) throws Exception
    {
        AmountDue[] amountDue = null;
        try ( Connection con = Connect.open(datasource); )
        {
            System.out.println("Con is " + (con == null ? "NULL" : "defined"));
            amountDue = getDue(con, clientId, can);
        }
        return amountDue;
    }
    public static AmountDue[] getDue(Connection con, String clientId, String can) throws SQLException
    {
        Map<String,AmountDue> cache = new Hashtable<String,AmountDue>();

        // Retrieve the levy balances
        try ( CallableStatement cs = con.prepareCall("{ ?=call vit_utilities.get_amount_due_by_month(p_client_id=>?,p_can=>?,p_year=>?,p_month=>null) }"); )
        {
            cs.registerOutParameter(1,oracle.jdbc.OracleTypes.CURSOR);
            cs.setString(2, clientId);
            cs.setString(3, can);
            cs.setString(4, null);
            cs.execute();

            try ( ResultSet rs = (ResultSet) cs.getObject(1); )
            {
                // Saved if needed due to future changes to call w/o us being told...
                //buffer.append("Columns for Callable Statement:\n");
                //ResultSetMetaData meta = rs.getMetaData();
                //for ( int column=1; column < meta.getColumnCount(); column++ )
                //{
                //    buffer.append(String.format("<li> %2d: %s </li>", column, meta.getColumnName(column)));
                //}

                while ( rs.next() )
                {
                    String year  = rs.getString("year");
                    String month = String.format("%02d", rs.getInt("month"));
                    String id    = String.format("%s%s", year, month);

                    AmountDue record = cache.get(id);
                    if ( record == null )
                    {
                        record = new AmountDue(clientId, can, year, month);
                        cache.put(id, record);
                    }

                    record.setAmountDue(rs);
                }
            }
        }


        // Retrieve sales and filing data
        try ( PreparedStatement ps = con.prepareStatement(
                                                  "with  sales (client_id, can, year, month, sales, taxes) "
                                                + "      as (select client_id, can, year, month, "
                                                + "                 sum(sales_price) as \"sales\", "
                                                + "                 sum(tax_amount) as \"taxes\" "
                                                + "            from sit_sales "
                                                + "           where status <> 'D' and sale_type in ('MV','MH','HE','VTM') "
                                                + "           group by client_id, can, year, month "
                                                + "         ), "
                                                + "      filings (client_id, can, year, month, reports, finalized, filed) "
                                                + "      as (select client_id, can, year, month, "
                                                + "                 count(distinct report_seq) as \"reports\", "
                                                + "                 sum(decode(report_status, 'C', 1, 0)) as \"finalized\", "
                                                + "                 sum(decode(file_date, null, 0, 1)) as \"filed\" "
                                                + "            from sit_sales_master "
                                                + "           where month < 13 "
                                                + "           group by client_id, can, year, month "
                                                + "         ), "
                                                + "      monrpt (client_id, can, year, month, saved) "
                                                + "      as (select client_id, key_id, key_year, reference_no, count(*) "
                                                + "            from sit_documents "
                                                + "           where document_type='MONRPT' "
                                                + "           group by client_id, key_id, key_year, reference_no "
                                                + "         ) "
                                                //
                                                + " select nvl(sales.year,filings.year) as \"year\",  "
                                                + "        nvl(sales.month,filings.month) as \"month\",  "
                                                + "        nvl(sales,0) as \"salesPrice\", nvl(taxes,0) as \"taxAmount\", "
                                                + "        nvl(reports,0) as \"reports\", nvl(finalized,0) as \"finalized\", "
                                                + "        nvl(filed,0) as \"filed\", nvl(saved,0) as\"saved\", "
                                                + "        nvl(taxdtl.start_date,to_date('12/31/'||(taxdtl.year-1),'mm/dd/yyyy')) as \"startDate\", "
                                                + "        decode(sales.client_id,null,'N','Y') as \"salesData\", "
                                                + "        decode(filings.client_id,null,'N','Y') as \"salesMasterData\" "
                                                + " from sales  "
                                                + "      full outer join filings on (filings.client_id=sales.client_id and filings.can=sales.can "
                                                + "                             and filings.year=sales.year and filings.month=sales.month  "
                                                + "                                 ) "
                                                + "      left outer join monrpt on (monrpt.client_id=filings.client_id and monrpt.can=filings.can "
                                                + "                             and monrpt.year=filings.year and monrpt.month=filings.month  "
                                                + "                                 ) "
                                                + "       join taxdtl on (taxdtl.client_id=nvl(sales.client_id,filings.client_id) "
                                                + "                       and taxdtl.can=nvl(sales.can,filings.can) "
                                                + "                       and taxdtl.year=nvl(sales.year,filings.year) "
                                                + "                       ) "
                                                + " where nvl(sales.client_id,filings.client_id)=? "
                                                + "   and nvl(sales.can,filings.can)=? "
                                                + "   and nvl(sales.year,filings.year)=nvl(?,nvl(sales.year,filings.year)) "
                                                + "   and nvl(sales.month,filings.month)=nvl(?,nvl(sales.month,filings.month)) "
                                                + "   and (nvl(taxdtl.start_date,to_date('12/31/'||(taxdtl.year-1),'mm/dd/yyyy')) < "
                                                + "           add_months(to_date(nvl(sales.month,filings.month)||'/1/'||nvl(sales.year,filings.year),'mm/dd/yyyy'),1) "
                                                + "        or filed > 0 "
                                                + "       ) "
                                                + " order by nvl(sales.year,filings.year) desc, nvl(sales.month,filings.month) desc"
                                                );
             )
        {
            ps.setString(1, clientId);
            ps.setString(2, can);
            ps.setString(3, null); // Year
            ps.setString(4, null); // Month

            try ( ResultSet rs = ps.executeQuery(); )
            {
                while ( rs.next() )
                {
                    String year  = rs.getString("year");
                    String month = String.format("%02d", rs.getInt("month"));
                    String id    = String.format("%s%s", year, month);

                    AmountDue record = cache.get(id);
                    if ( record == null )
                    {
                        record = new AmountDue(clientId, can, year, month);
                        cache.put(id, record);
                    }

                    record.setSales(rs);
                }
            }
        }

        String[] keys = (String[])cache.keySet().toArray(new String[0]);
        Arrays.sort(keys);
        AmountDue[] records = new AmountDue[keys.length];
        for ( int i=0; i < keys.length; i++ )
        {
            records[i] = (AmountDue) cache.get(keys[i]);
        }
        return records;
    }







    public      String              clientId            = null;
    public      String              can                 = null;
    public      String              year                = null;
    public      String              month               = null;

    public      String              id                  = null;


    public      boolean             amountDueData       = false;    // vit_utilities.get_amount_due_by_month

    public      double              msaleLevy           = 0.0;
    public      double              msaleLevyBal        = 0.0;
    public      double              msalePenBal         = 0.0;

    public      double              mfineLevy           = 0.0;
    public      double              mfineLevyBal        = 0.0;
    public      double              mfinePenBal         = 0.0;

    public      double              mnsfLevy            = 0.0;
    public      double              mnsfLevyBal         = 0.0;
    public      double              mnsfPenBal          = 0.0;

    public      double              amountDue           = 0.0;


    public      boolean             salesData           = false;    // sit_sales table
    public      double              salesPrice          = 0.0;
    public      double              taxAmount           = 0.0;


    public      boolean             salesMasterData     = false;    // sit_sales_master table
    public      int                 reports             = 0;        // distinct report_seq values
    public      int                 finalized           = 0;        // report_status = 'C'
    public      int                 filed               = 0;        // records w/ file_date not null

    public      int                 saved               = 0;        // sit_documents table
                                                                    // document_type = 'MONRPT'
    public      boolean             isPayable           = false;    // salesData and amountDue > 0 and document saved
    public      boolean             isComplete          = false;    // salesData && amountDue == 0 and finalized and filed

    public      LocalDate           startDate           = null;

    public      String              dueDate             = "";



    // sloppy, quick fix to allow matching of amount due records
    // with records already part of the payment cart.
    // Really need to look at whether there is a better way to
    // match and track this.
    public      boolean             isInCart            = false;


    // Updates record cart flag
    public static void matchToCart(Payments payments, AmountDue[] dueRecords)
    {
        if ( payments == null || dueRecords == null )
        {
            return;
        }

        for ( AmountDue record : dueRecords )
        {
            record.isInCart = payments.isInCart(record.can, record.year, record.month);
        }

        return;
    }




    //public static AmountDue[] retrieveAll(ResultSet rs) throws SQLException
    //{
    //    ArrayList<AmountDue> results = new ArrayList<AmountDue>();
    //    while ( rs.next() )
    //    {
    //        results.add(AmountDue.retrieve(rs));
    //    }
    //
    //    return results.toArray(new AmountDue[0]);
    //}
    //public static AmountDue retrieve(ResultSet rs) throws SQLException
    //{
    //    return new AmountDue(rs);
    //}


    BigDecimal amount   = new BigDecimal("0.00"); // Forces double value to two decimal places
    public AmountDue setAmountDue(ResultSet rs) throws SQLException
    {
        // isDefined and ! equal client/can
        //clientId            = rs.getString("clientId");
        //can                 = rs.getString("can");
        if ( notDefined(id) )
        {
            year                = rs.getString("year");
            month               = String.format("%02d", rs.getInt("month"));

            id = String.format("%s%s", year, month);
        }

        amountDueData       = true;

        msaleLevy           = amount.add(rs.getBigDecimal("msale_levy")).doubleValue();
        msaleLevyBal        = amount.add(rs.getBigDecimal("msale_levybal")).doubleValue();
        msalePenBal         = amount.add(rs.getBigDecimal("msale_penbal")).doubleValue();

        mfineLevy           = amount.add(rs.getBigDecimal("mfine_levy")).doubleValue();
        mfineLevyBal        = amount.add(rs.getBigDecimal("mfine_levbal")).doubleValue();
        mfinePenBal         = amount.add(rs.getBigDecimal("mfine_penbal")).doubleValue();

        mnsfLevy            = amount.add(rs.getBigDecimal("mnsf_levy")).doubleValue();
        mnsfLevyBal         = amount.add(rs.getBigDecimal("mnsf_levbal")).doubleValue();
        mnsfPenBal          = amount.add(rs.getBigDecimal("mnsf_penbal")).doubleValue();

        amountDue           = amount.add(rs.getBigDecimal("amount_due")).doubleValue();

        isPayable           = amountDue > 0.0  && reports > 0 && reports == finalized;
        isComplete          = amountDue == 0.0 && reports > 0 && reports == finalized && reports == filed;


        return this;
    }


    public AmountDue setSales(ResultSet rs) throws SQLException
    {
        // isDefined and ! equal client/can
        //clientId            = rs.getString("clientId");
        //can                 = rs.getString("can");
        if ( notDefined(id) )
        {
            year  = rs.getString("year");
            month               = String.format("%02d", rs.getInt("month"));

            id = String.format("%s%s", year, month);
        }


        // Setting salesData/salesMasterData

        salesData           = ("Y".equals(rs.getString("salesData")));
        salesPrice          = amount.add(rs.getBigDecimal("salesPrice")).doubleValue();
        taxAmount           = amount.add(rs.getBigDecimal("taxAmount")).doubleValue();

        salesMasterData     = ("Y".equals(rs.getString("salesMasterData")));
        reports             = rs.getInt("reports");
        finalized           = rs.getInt("finalized");
        filed               = rs.getInt("filed");

        saved               = rs.getInt("saved");

        startDate           = rs.getDate("startDate").toLocalDate();

        isPayable           = amountDue > 0.0  && reports > 0 && reports == finalized;
        isComplete          = amountDue == 0.0 && reports > 0 && reports == finalized && reports == filed;


        return this;
    }


    SimpleDateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy");

    public RecordState getFinalizedState()
    {
        return  (finalized == 0 ? RecordState.NONE
                                : (finalized == reports ? RecordState.ALL
                                                        : RecordState.SOME
                                    )
                    );
    }
    public RecordState getFiledState()
    {
        return  (filed == 0 ? RecordState.NONE
                            : (filed == reports ? RecordState.ALL
                                                : RecordState.SOME
                                )
                    );
    }

    public static final NumberFormat currency = NumberFormat.getCurrencyInstance();
    static 
    {
        DecimalFormatSymbols symbols = ((DecimalFormat)currency).getDecimalFormatSymbols();
        symbols.setCurrencySymbol("");
        ((DecimalFormat)currency).setDecimalFormatSymbols(symbols);
    }


    public static String showRecords(AmountDue[] amounts)
    {
        StringBuilder builder = new StringBuilder();

        builder.append(String.format("%-18s  %-4s  %2s   %5s  %13s  %13s  %9s   %9s  %9s  %9s   %6s  %7s  %7s   %14s   %5s  %5s  %14s  %14s  %2s  %2s  %2s  %2s  %6s  %6s  %7s\n",
                                    "Account", "Year", "MO",

                                    "DData",
                                    "Levy", "Balance", "Penalty",
                                    "Fine", "Balance", "Penalty",
                                    "NSF", "Balance", "Penalty",
                                    "Amount Due",

                                    "SData", "MData", 
                                    "Sales", "Tax", "R", "F", "P",

                                    "S",
                                    "Final", "Posted", "Payable"
                                    )
                        );
        String yearLastDisplayed = null;
        for ( AmountDue amount : amounts )
        {
            if ( yearLastDisplayed == null ) yearLastDisplayed = amount.year;
            if ( ! yearLastDisplayed.equals(amount.year) )
            {
                yearLastDisplayed = amount.year;
                builder.append("\n\n");
            }

            builder.append(amount.toString());
        }

        return builder.toString();
    }

    public String toString()
    {
        return  String.format("%-18s  %-4s  %2s   %5b  %13s  %13s  %9s   %9s  %9s  %9s   %6s  %7s  %7s   %14s   %5b  %5b  %14s  %14s  %2d  %2d  %2d  %2d  %6s  %6s  %7s\n",
                                can, year, month, 

                                amountDueData,
                                currency.format(msaleLevy), currency.format(msaleLevyBal), currency.format(msalePenBal),
                                currency.format(mfineLevy), currency.format(mfineLevyBal), currency.format(mfinePenBal),
                                currency.format(mnsfLevy),  currency.format(mnsfLevyBal),  currency.format(mnsfPenBal),
                                currency.format(amountDue),

                                salesData, salesMasterData,
                                currency.format(salesPrice), currency.format(taxAmount), 
                                reports, finalized, filed, 

                                saved,
                                getFinalizedState(), getFiledState(),
                                (isPayable ? isPayable : isComplete ? "complete" : false)
                                );
    }    


    // Used to sort by year/month order
    public int compareTo(Object other)
    {
        return compareTo((AmountDue)other);
    }
    public int compareTo(AmountDue other)
    {
        return other.id.compareTo(id);
    }


    public static AmountDue[] defaultMissingMonths(AmountDue[] currentList)
    {
        if ( currentList == null || currentList.length == 0 ) return currentList;
        String can = currentList[0].can;

        SortedSet<String> set = new TreeSet<String>();
        set.add(Year.now().toString());
        for ( AmountDue e : currentList )
        {
            set.add(e.year);
        }

        String   currentYearMonth = YearMonth.now().toString().replaceAll("[^0-9]","");

        String[] months = new String[] { "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12" };
        String[] years  = (String[]) set.toArray(new String[0]);
        set.clear();

        Map<String,AmountDue> map = new Hashtable<String,AmountDue>();
        for ( AmountDue e : currentList )
        {
            map.put(String.format("%s%s",e.year,e.month),e);
        }

        //for ( String year : years )
        int minYear = 2015;
        for ( int year=Year.now().getValue(); year >= minYear; year-- )
        {
            for ( String month : months )
            {
                String yearMonth = String.format("%d%s", year, month);
                if ( currentYearMonth.compareTo(yearMonth) < 0 ) continue;
                if ( map.containsKey(yearMonth) ) continue;
                map.put(yearMonth, new AmountDue(currentList[0].clientId, currentList[0].can, ""+year, month));
            }
        }

        ArrayList<AmountDue> list = new ArrayList<AmountDue>();
        String[] keys = map.keySet().toArray(new String[0]);
        for ( String key : keys )
        {
            list.add(map.get(key));
        }
        AmountDue[] newList = (AmountDue[]) list.toArray(new AmountDue[0]);
        Arrays.sort(newList);

        return newList;
    }


    public static boolean notDefined(String... values)
    {
        if ( values != null )
        {
            for (String value : values)
            {
                if ( value != null ) return false;
            }
        }

        return true;
    }
}
