<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"
         import="java.util.*, java.io.*, java.sql.*, java.util.logging.*, oracle.jdbc.*, java.text.*,
                 act.log.Logs, act.log.SITLog, act.util.Sysutil, act.util.AppConfiguration,  act.sit.*, java.time.*"
%>
<%@ page import="java.time.format.DateTimeFormatter" %><%--
    DN - 04/30/2018 - PRC 194602
        This PRC is applied to both Dallas and Harris County
        Set a default value for getStartDate in case the start_date in "taxdtl" table is null
        Default value for getStartDate should be the year of the selected filing year with "-01-01"
    DN - 08/21/2018 - PRC 194803
        Updated the sales type "VTM" to "VM"

--%><jsp:useBean    id="dealerships"    class="act.sit.Dealerships"     scope="session"
/><jsp:useBean      id="payments"       class="act.sit.Payments"        scope="session"
/><jsp:useBean      id="payment"        class="act.sit.Payment"         scope="session"
/><jsp:useBean      id="recents"        class="act.sit.Recents"         scope="session"
/><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1.
    response.setHeader("Pragma", "no-cache");   // HTTP 1.0.
    response.setHeader("Expires", "0");         // Proxies.
    session.setMaxInactiveInterval(60*40);      // 40 minutes

    String url = request.getServletPath();// used in next variable
    String currentPage = url.substring( url.lastIndexOf('/')+1, url.length() );


    // Has user already logged in?
    SITAccount sitAccount = (SITAccount) session.getAttribute("sitAccount");
    if ( ! currentPage.startsWith("login") && (sitAccount == null || ! sitAccount.isValid()) )
    {
        String loginPage = request.getRequestURL().toString().replaceAll("^(.*)/[^/]*$","$1/login.jsp");
        response.sendRedirect(loginPage);
        return;
    }


    String pdfConverterURL = "http://apollo:100/convert2PDF.php";
    String tempDirectory = "/usr2/webtemp/";    // Used in pages in /forms/ directory (_monthly, _yearly, _file_upload)
    String tempURL = "/dev60temp/";             // _getUploadedFiles, _viewForm, _widgets

    int currentYear = Calendar.getInstance().get(Calendar.YEAR);


    Map<String,String> onlineHelp = (Map<String,String>) session.getAttribute("SITOnlineHelp");
    if ( onlineHelp == null )
    {
        session.setAttribute("SITOnlineHelp", onlineHelp=new Hashtable<String,String>());
    }
    String onlineHelpURL = onlineHelp.get(currentPage);



    int max_report_seq = 0; // used on widgets for sales page
    int report_seq = 0; // used on widgets for sales page
    boolean showLegend = false;
    
    boolean finalize_on_pay = "Y".equals((String)session.getAttribute("finalize_on_pay"));

    String can = nvl(request.getParameter("can"), "");
    String year = nvl(request.getParameter("year"), "");
    String month = nvl(request.getParameter("month"), "");
    String category = nvl(request.getParameter("category"));
    String dealerType = nvl(request.getParameter("dealer_type"));

    String      formName            = null;
    String      categoryName        = null;

    boolean viewOnly = sitAccount!= null ? sitAccount.getUser().viewOnly() : false;

    // Attempt to locate the selected dealership
    Dealership  dealership          = dealerships.get(can);
    if ( dealership != null )
    {
        dealerType      = ""+dealership.dealerType;
        category        = dealership.category;
        categoryName    = dealership.categoryName;
        formName        = dealership.formName;

        recents.add(dealership.can, dealership.nameline1);
    }


    // These are temporary. Need to convert to using a maintenance-friendly, descriptive, camelCase name
    Dealerships ds = dealerships;
    Dealership  d  = null;

    session.setAttribute("ds", dealerships);


    String current_page = currentPage;

    String form_name        = formName;
    String categoryNomen    = categoryName;


    DateTimeFormatter formatter = DateTimeFormatter.BASIC_ISO_DATE.ofPattern("MMM dd, yyyy");
    String sitVersion       = "SIT 1.6";
    String updatedDate      = LocalDate.of(2018,9,21).format(formatter);


%><%!
    String[][] dealerCategories = new String[][] {
                                                { "0",      "MV",     "50_246",   "Motor Vehicle" },  // Default

                                                { "1",      "MV",     "50_246",   "Motor Vehicle" },
                                                { "2",      "VM",     "50_260",   "Vessel, Trailer, and Outboard" },
                                                { "3",      "HE",     "50_266",   "Heavy Equipment" },
                                                { "4",      "MH",     "50_268",   "Retail Manufactured Housing" }
                                        };


    boolean   nvl(String val,  boolean def) { return ( isDefined(val) ? isTrue(val.trim()) : def ); }
    int       nvl(String val,  int     def) { try { return Integer.parseInt  (val.replaceAll("[^\\d.-]","")); } catch (Exception e) {} return def; }
    long      nvl(String val,  long    def) { try { return Long.parseLong    (val.replaceAll("[^\\d.-]","")); } catch (Exception e) {} return def; }
    double    nvl(String val,  double  def) { try { return Double.parseDouble(val.replaceAll("[^\\d.-]","")); } catch (Exception e) {} return def; }
    String    sanitizeNumber( String value) { return nvl( value,"0").replace("(","-").replaceAll("[$|,)]","");}

    boolean isDefined(String... values)
    {   if ( values == null || values.length == 0 ) return false;
        for ( String value : values )
        {   if ( value == null || value.length() == 0 ) return false;
        }
        return true;
    }
    boolean notDefined(String... values)
    {   if ( values == null || values.length == 0 ) return true;
        for ( String value : values )
        {   if ( value != null && value.length() > 0 ) return false;
        }
        return true;
    }
    String nvl(String... values)
    {
        if ( values != null )
        {
            for ( String value : values )
            {
                if ( value == null ) continue;
                return value;
            }
        }

        return "";
    }
    String nvl(Object value, String def)
    {
        return (value == null|| ! (value instanceof String) ? def : (String) value);
        
    }
    
    String nvl(String value, String def)
    {
        return ( notDefined( value ) ) ? def : value;
        
    }
    
    boolean isTrue(String value)
    {
        return value != null && value.toUpperCase().matches("(Y|YES|TRUE)");
    }

    public StringBuffer getAddress(Dealership d){
        StringBuffer sb = new StringBuffer();
        if (isDefined(d.nameline1)){sb.append("<strong>" + d.nameline1 + "</strong>");}
        //if (isDefined(d.nameline1)){sb.append("<strong>" + d.nameline1 + "</strong> - " + d.can);}
        if (isDefined(d.nameline2)){sb.append("<br>" + d.nameline2);}
        if (isDefined(d.nameline3)){sb.append("<br>" + d.nameline3);}
        if (isDefined(d.nameline4)){sb.append("<br>" + d.nameline4);}
        sb.append("<br>" + nvl(d.city) + ", " + nvl(d.state) + " " + formatZip(d.zipcode));
        if (isDefined(d.phone)){sb.append("<br>Phone: " + formatPhone(d.phone));}
        sb.append("<br>Dealer#: " + d.can);
        //sb.append("<br>Account: " + d.aprdistacc);
        return sb;
    }


    public String formatZip(String z){
        return z.replaceAll("^([0-9]{5})([0-9]{4})$","$1-$2");
    }
    public String formatPhone(String z)
    {
        return z.replaceAll("^([0-9]{3})([0-9]{3})([0-9]{4})$","($1) $2-$3");
    }

    public String formatMoney(String amount)
    {
        return formatMoney(nvl(amount,0.0));
    }
    public String formatMoney(double amount)
    {
       return  NumberFormat.getCurrencyInstance().format(amount) ;
    }
    
    // PRC 190602 - 06/14/2018 retrieve the startDate, startDate's month, startDate's year
    // Default value will be the year of the selected filing year -1 with "12-31" in case the start_date in "taxdtl" table is null or doesn't exist
    public String getStartDate( Connection conn,
                                            PreparedStatement ps,
                                            ResultSet rs,
                                            String clientId,
                                            String can,
                                            String year
                                            ) throws Exception {
        String startDate = "";
        try {
            ps = conn.prepareStatement("select distinct start_date"
                                      +"    from taxdtl"
                                      +" where client_id = ?"
                                      +"    and can = ?"
                                      +"    and year = ? "
                                      );
            ps.setString(1, clientId);
            ps.setString(2, can);
            ps.setString(3, year);
            
            rs = ps.executeQuery();
            
            if( !rs.isBeforeFirst() ) { return startDate; }
            if ( rs.next() ) {
                startDate = nvl( rs.getString("start_date"), "");
                
            }
            
        } catch (Exception e){
            throw e;
        } finally {
			try { rs.close(); } catch (Exception e){} rs = null;
			try { ps.close(); } catch (Exception e){} ps = null;
		}
        
        return startDate;
    }
    
     // PRC 198588 - Moved 2 functions below from _monthly and yearly page
    public String getClientPref(Connection conn, PreparedStatement ps, ResultSet rs, String clientId, String pref) throws Exception{
		String clientPref = "";
		try {
		
			ps = conn.prepareStatement("select act_utilities.get_client_prefs(?,?) from dual");
			ps.setString(1,clientId);
			ps.setString(2,pref);
			
			rs = ps.executeQuery();
			
			if(rs.next()){
				clientPref = rs.getString(1);
			}
		} catch(Exception e){
			throw e;
		} finally{
			try { ps.close();} catch(Exception e){}
			ps = null;
			try { rs.close();} catch(Exception e){}
			rs = null;
		}
	return clientPref;
	}
	
	public String getSitClientPref(Connection conn, PreparedStatement ps, ResultSet rs, String clientId, String pref) throws Exception{
		String sitClientPref = "";
		try {
		
			ps = conn.prepareStatement("select description from sit_codeset"
									  +" where client_id = ? and type_code= 'CLIENT'"
									  +"	and code = ?"
									  );
			ps.setString(1,clientId);
			ps.setString(2,pref);
			
			rs = ps.executeQuery();
			
			if(rs.next()){
				sitClientPref = rs.getString(1);
			}
		} catch(Exception e){
			throw e;
		} finally{
			try { ps.close();} catch(Exception e){}
			ps = null;
			try { rs.close();} catch(Exception e){}
			rs = null;
		}
	return sitClientPref;
	}

    public String getSitClientPref(String clientId, String pref) throws Exception {
        String sitClientPref = "";
        try ( Connection conn = connect() ) {
            try ( PreparedStatement ps = conn.prepareStatement(
                                                "select description from sit_codeset"
                                                +" where client_id = ? and type_code= 'CLIENT'"
                                                +"	and code = ?"
                                                )) {
                ps.setString(1,clientId);
                ps.setString(2, pref);

                try (ResultSet rs = ps.executeQuery() ){
                    if ( rs.next() ){
                        sitClientPref = rs.getString(1);
                    }
                } catch (Exception e){
                    throw e;
                }
            } catch (Exception e){
                throw  e;
            }
        } catch (Exception e){
            throw e;
        }
        return sitClientPref;
    }
    

    public String numberFormat( String number ) throws Exception
    {
        return number.replaceAll("[^0-9- | .]+","");
    }
    public String dateFormat( java.util.Date date ) throws Exception 
    {
        return (new SimpleDateFormat("MM/dd/yyyy")).format( date );
    }

    public int getMonth( java.util.Date date ) throws Exception
    {
        return date.toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDate().getMonthValue();
    }

    public String getYear( java.util.Date date ) throws Exception
    {
        return ""+date.toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDate().getYear();
    }

    public java.util.Date convertToDate( String date ) throws Exception
    {
        return (new SimpleDateFormat("yyyy-MM-dd")).parse( date );
    }

    //connection method
    private String datasource = "jdbc/sit";
    Connection connect() throws Exception {
        return act.util.Connect.open(datasource);
    }

%>