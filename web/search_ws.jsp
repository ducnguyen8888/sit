<%--
  Created by IntelliJ IDEA.
  User: Duc.Nguyen
  Date: 9/6/2018
  Time: 10:25 AM
  To change this template use File | Settings | File Templates.
--%>

<%@ page import="java.lang.reflect.*,java.time.*,java.time.format.*" %><%@ include file="_configuration.inc"
%><%
    boolean         isSameServer         = nvl( request.getHeader("Referer")).indexOf(request.getHeader("Host")) > 0;
    boolean         wasPosted            = "POST".equals(request.getMethod());

    String          clientId             = sitAccount.getClientId();

    String          dealershipNo         = nvl(request.getParameter("no"));
    String          dealershipName       = nvl(request.getParameter("name"));
    String          dealershipAddress    = nvl(request.getParameter("address"));
    String          userName             = nvl(request.getParameter("userName"));
    String          userId               = nvl(request.getParameter("userId"));

    Dealership[]    viewDealerships      = null;

    if( isSameServer
            && wasPosted
            && sitAccount.getUser().viewOnly()
            && sitAccount.isValid()
            ){
        if( atLeastOneSpecified( dealershipNo,
                                    dealershipName,
                                    dealershipAddress,
                                    userName,
                                    userId )
                ){
            try {
                SearchCriteria criteria = new SearchCriteria(dealershipNo, dealershipName, dealershipAddress, userName, userId);
                sitAccount.loadDealerships(criteria);
                viewDealerships = (Dealership[]) sitAccount.dealerships.toArray(new Dealership[0]);
                out.println(" {\"searchDealershipsRequest\":\"success\",\"data\":{\"searchDealerships\":\"success\",\"dealerships\":"+toJson(viewDealerships)+"}}");
            } catch (Exception e){
                String error = e.toString().replaceAll("\\\\n","").replaceAll("\\\\\"","\\\"");
                out.println(String.format( "{\"searchDealershipsRequest\":\"success\",\"data\":{\"searchDealerships\":\"failure\",\"detail\":"+ error+"}}"));
            }

        } else {
                out.println(String.format("{\"searchDealershipsRequest\":\"failure\",\"detail\":\"Not all required information is provided\"}"));
        }

    } else {
                out.println(String.format("{\"searchDealershipsRequest\":\"failure\",\"detail\":\"Request can not be processed\"}"));
            }

%><%!
    public StringBuffer getDealerAddress(Dealership d){
        StringBuffer sb = new StringBuffer();
        if (isDefined(d.nameline1)){sb.append(d.nameline1 );}
        if (isDefined(d.nameline2)){sb.append("<br>" + d.nameline2);}
        if (isDefined(d.nameline4)){sb.append("<br>" + d.nameline4);}
        sb.append("<br>" + nvl(d.city) + ", " + nvl(d.state));
        return sb;
    }

    public boolean atLeastOneSpecified(String account,
                                       String name,
                                       String address,
                                       String userName,
                                       String id) {
        return ( isDefined(account)
                || isDefined(name)
                || isDefined(address)
                || isDefined(userName)
                || isDefined(id));
    }

    public String toJson(Object obj)
    {
        boolean isClassArray = false;
        StringBuilder arrBuffer = new StringBuilder();
        StringBuilder buffer = new StringBuilder();
        Object arrayElement = null;
        int    arrayLength  = 0;

        if ( obj == null ) return ("");

        // If this is an array we need to handle each element individually
        if ( obj.getClass().isArray() )
        {
            arrayLength = java.lang.reflect.Array.getLength(obj);
            buffer.append("[ ");
            if ( arrayLength > 0 )
            {
                arrayElement = java.lang.reflect.Array.get(obj, 0);
                buffer.append(toJson(arrayElement));
                for ( int j=1; j < arrayLength; j++ )
                {
                    buffer.append(",\n");
                    arrayElement = java.lang.reflect.Array.get(obj, j);
                    buffer.append(toJson(arrayElement));
                }
            }
            buffer.append(" ]");
            return buffer.toString();
        }


        Field [] fields = obj.getClass().getDeclaredFields();
        for ( int i=0; i < fields.length; i++ )
        {
            if ( fields[i].getModifiers() != Modifier.PUBLIC ) continue;

            Class  classType  = fields[i].getType();

            String fieldName  = fields[i].getName();
            String fieldValue = "";

            try
            {
                if ( fields[i].get(obj) != null )
                {
                    if ( fields[i].getType().equals(java.lang.Integer.TYPE) )
                    {
                        fieldValue = ""+fields[i].getInt(obj);
                    }
                    else if ( fields[i].getType().equals(java.lang.Boolean.TYPE) )
                    {
                        fieldValue = ""+fields[i].getBoolean(obj);
                    }
                    else if ( fields[i].getType().equals(java.lang.Long.TYPE) )
                    {
                        fieldValue = ""+fields[i].getLong(obj);
                    }
                    else if ( fields[i].getType().equals(java.lang.Double.TYPE) )
                    {
                        fieldValue = ""+fields[i].getDouble(obj);
                    }
                    else if ( fields[i].getType().getName().equals("java.lang.String") )
                    {
                        fieldValue = "\"" + nvl((String)fields[i].get(obj)).replaceAll("\\\"","\\\\\"") + "\"";
                    }
                    else
                    {
                        if ( fields[i].get(obj).getClass().isArray() )
                        {
                            arrBuffer.setLength(0);
                            isClassArray = fields[i].getType().toString().startsWith("class [L")
                                    && ! classType.getName().equals("[Ljava.lang.String;");
                            arrayLength = java.lang.reflect.Array.getLength(fields[i].get(obj));
                            for (int j = 0; j < arrayLength; j++)
                            {
                                arrayElement = java.lang.reflect.Array.get(fields[i].get(obj), j);
                                arrBuffer.append("\n { \"" + fieldName.replaceAll("s$","") + "\": ");
                                arrBuffer.append((isClassArray ? "\n" + toJson(arrayElement) : "\"" + arrayElement + "\""));
                                arrBuffer.append(" } ");
                                if ( j < arrayLength-1 ) arrBuffer.append(",");
                                arrBuffer.append(" ");
                            }
                            fieldValue = "[ " + arrBuffer.toString() + " ]\n";
                            arrBuffer.setLength(0);
                        }
                        else
                        {
                            // We'll assume this is a simple Class
                            if ( fields[i].get(obj) != this ) fieldValue = "\n" + toJson(fields[i].get(obj));
                        }
                    }
                }
            }
            catch (Exception e)
            {
                fieldValue = e.toString();
            }

            if ( buffer.length() > 0 ) buffer.append(", ");
            buffer.append( "\"" + fieldName + "\": " + (fieldValue.length() == 0 ? "\"\"" : fieldValue));
        }

        return "{ " + buffer.toString() + " }";
    }
%>

