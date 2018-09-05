<%@ page import="java.lang.reflect.*,java.time.*,java.time.format.*" %><%@ include file="_configuration.inc"
%><%--
    Need to define/include error handling
--%><%
    String userid               = sitAccount.getUser().getUserId();
    String clientId             = sitAccount.getClientId();

    can = "99B03507000000000";//request.getParameter("can");


    // If no CAN then no data
    if ( missingValues(clientId, can, year) ) return;

    try ( Connection con = act.util.Connect.open(datasource); )
    {
        // Does not show any future-date records 
        // Pre-start data only shows if ALL are finalized (SalesMaster)
        // Pay option is shown only when totaldue > 0 and document (document_type MONRPT) saved
        //              in sit_documents

        AmountDue[] due = AmountDue.getDue(datasource, clientId, can);


        ArrayList<AmountDue> recordList = new ArrayList<AmountDue>();
        for ( AmountDue monthRecord : due )
        {
            if ( ! monthRecord.salesData && monthRecord.saved == 0 )
            {
                continue;
            }

            if ( monthRecord.startDate != null )
            {
                LocalDate recordDate = LocalDate.parse(String.format("%s/1/%s", monthRecord.month, monthRecord.year),startDateFormat).plusMonths(1);
                if ( monthRecord.startDate.isAfter(recordDate) )
                {
                    continue;
                }
            }

            recordList.add(monthRecord);
        }
        if ( recordList.size() == 0 )
        {
            recordList.add(new AmountDue(clientId, can, Year.now().toString(), String.format("%02d",YearMonth.now().getMonth().getValue())));
        }
        due = recordList.toArray(new AmountDue[0]);
        due = AmountDue.defaultMissingMonths(due);
        Arrays.sort(due);
        AmountDue.matchToCart(payments,due);


        // -- Currently missing due date, action (edit/view), and pay
        // -- Filter future date records
        // -- Pre-start date records will only show if all are finalized (salesMaster)
        // -- Pay option is shown only when totalDue > 0 and document saved (document_type MONRPT)

        out.println(String.format("%s",toJson(due)));
    }
    catch (Exception exception)
    {
        out.println("Exception: " + exception.toString());
    }
%><%!

    public static boolean missingValues(String... values)
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


    DateTimeFormatter startDateFormat = DateTimeFormatter.ofPattern("MM/d/yyyy");

    public String toJson(AmountDue[] records)
    {
        StringBuilder buffer = new StringBuilder();


        Map<String,ArrayList> map = new Hashtable<String,ArrayList>();
        ArrayList<AmountDue> yearSet = null;
        for ( AmountDue e : records )
        {
            yearSet = map.get(e.year);
            if ( yearSet == null )
            {
                yearSet = new ArrayList<AmountDue>();
                map.put(e.year, yearSet);
            }
            yearSet.add(e);
        }


        // Get the keys
        String[] keys = map.keySet().toArray(new String[0]);
        Arrays.sort(keys);
        for ( String key : keys )
        {
            yearSet = map.get(key);
            Collections.sort(yearSet);
            StringBuilder group = new StringBuilder();
            for ( AmountDue due : yearSet )
            {
                group.append(String.format(",\n\"%d\": %s",Integer.parseInt(due.month),toJson(due)));
            }
            group.delete(0,1);
            buffer.append(String.format(",\n\"%s\": { %s }",key,group.toString()));
        }
        buffer.delete(0,1);

        return String.format("{ %s }",buffer.toString());
    }

    /** Creates a JSON formatted string of the public fields of the specified object.
     *  Returns a JSON String of the public fields for this class. Field names
     *  are the used as the Element names with the current values used as the
     *  values.
     */
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