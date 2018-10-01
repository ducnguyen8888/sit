<%@ include file="_configuration.inc"
%><%
    response.addHeader("Pragma" , "No-cache") ;
    response.addHeader("Cache-Control", "no-cache") ;
    response.addDateHeader("Expires", 0);
    
    //boolean         isSameServer    = nvl( request.getHeader("Referer")).indexOf(request.getHeader("Host")) > 0;
    boolean         wasPosted       = "POST".equals(request.getMethod());
    
    String          clientId        = nvl(request.getParameter("clientId"));
    double          sales           = nvl(request.getParameter("sales"),0.00);
    String          salesType       = nvl(request.getParameter("type"));
    
    if ( wasPosted
            && sitAccount.isValid() ) {
          
          if ( isDefined( clientId)
            && isDefined(can)
            && isDefined(year)
            && isDefined(salesType) ) {
                
                try {
                    String salesTax = getSaleTax(clientId, can, year, sales, salesType);
                    %>{"sendRequest":"success", "data":{"calculateSalesTax":"success", "tax":"<%= salesTax %>", "detail":"Sales tax is successfully calculated"}}<%
                } catch (Exception e) {
                    %>{"sendRequest":"success", "data":{"calculateSalesTax":"failure","tax":"0.00","detail":"<%= e.getMessage() %>"}}<%
                }
            } else {
                %>{"sendRequest":"failure", "tax":"0.00" ,"detail": "Not all required information is provided"}<%
            }
        
   
    } else {
         %>{"sendRequest":"failure","tax":"0.00", "detail": "Request can not be processed"}<%
    }
%><%!
    Exception TAX_NOT_CALCULATED    = new Exception("Failed to calculate sales tax");
    public String  getSaleTax(String clientId, 
                                String can, 
                                String year, 
                                double sales, 
                                String salesType
                                ) throws Exception {
        String salesTax = null;
        try ( 
                Connection              conn    = connect(); 
                PreparedStatement       ps      = conn.prepareStatement("select vit_utilities.calculate_tax_amount(?, ?, ?, ?, ?)"
                                                                       +"   from dual");
            ){
            
             
                ps.setString(1, clientId);
                ps.setString(2, can);
                ps.setString(3, year);
                ps.setDouble(4, sales);
                ps.setString(5, salesType);
                
                try ( ResultSet rs =  ps.executeQuery(); ){
                    if( !rs.isBeforeFirst() ) throw TAX_NOT_CALCULATED;
                    
                    if ( rs.next() ) {
                      salesTax = rs.getString(1);
                    }
                } 
        } catch ( Exception e) {
            throw e;
        }
        
        return salesTax;
    }

%>