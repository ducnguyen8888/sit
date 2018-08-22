<%@ page import="java.util.*,java.sql.*,
                 act.util.*" 
%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");

    String datasource = "jdbc/sit";

    Connection conn = null;
    String objectName = null;

    Connection [] connections = null;

    try {
        %>
        <style>
            h3 { margin-bottom: 5px; padding-bottom: 0px; }
            h4 { margin-bottom: 10px; padding-bottom: 0px; text-decoration: underline; color: darkblue; width: 830px; padding: 5 10px; border: 1px solid darkblue; background-color: lightgrey; }
            h5 { margin-top: 15px; margin-bottom: 5px; padding: 0px; color: darkgrey; font-style: italic; }
            h6 { margin: 0px; padding: 0px; color: darkgrey; }
            .content { padding: 10px 15px; }
            .content .content { padding: 5px 15px; }
        </style>
        <pre><%
        %><%= String.format("%12s:  %s\n", "Datasource", datasource) %><%


        long start = System.currentTimeMillis();
        conn = Connect.open(datasource);

        connections = new Connection[] {
        Connect.open(datasource),
        Connect.open(datasource),
        Connect.open(datasource)
        };

        GetObjectSummary [] summaries = new GetObjectSummary[] {
                                                new GetObjectSummary(connections[0], "SIT_EPAY"),
                                                new GetObjectSummary(connections[1], "SIT_EPAYDTL"),
                                                new GetObjectSummary(connections[2], "SIT_EPAY_SEQUENCE")
                                                };
        GetObjectSummary gos = summaries[0];
        for ( GetObjectSummary summary : summaries ) summary.start();


        %><%= String.format("%12s:  %s\n", "Database", 
                Connect.getUser(conn) + "@" + Connect.getName(conn)) %><%
        %><%= String.format("%12s:  %s\n", "Schema", 
                gos.getSchema(conn)) %><%
        %><%= String.format("%12s:  %s\n\n", "Roles", 
                gos.getRoles(conn)) %><%
        for ( GetObjectSummary summary : summaries ) summary.join();
        %><h6> Total Duration: <%= System.currentTimeMillis() - start %></h6><%

        StringBuffer buffer = new StringBuffer();
        buffer.insert(0,String.format("<h6> Total Duration: %s</h6>",""+(System.currentTimeMillis() - start)));
        for ( GetObjectSummary summary : summaries ) 
            buffer.insert(0,String.format("<h6> %s Duration: %s</h6>",
                                            summary.objectName, ""+summary.duration));
        buffer.append("<hr>");
        %><%= buffer.toString() %><%
        for ( GetObjectSummary summary : summaries ) {
            %><%= summary.summary() %><%
        }

if ( false ) {
        objectName = "SIT_EPAY";
        %><%= String.format("<h4>%s</h4>", objectName) %><%
        %><div class="content"><%= gos.getObjectInformation(conn,objectName) %></div><%

        objectName = "SIT_EPAYDTL";
        %><%= String.format("<h4>%s</h4>", objectName) %><%
        %><div class="content"><%= gos.getObjectInformation(conn,objectName) %></div><%


        objectName = "SIT_EPAY_SEQUENCE";
        %><%= String.format("<h4>%s</h4>", objectName) %><%
        %><div class="content"><%= gos.getObjectInformation(conn,objectName) %></div><%
}
    } catch (Exception e) {
        %><li> Exception: <%= e.toString() %></li><%
    } finally {
        if ( conn != null ) {
            try { conn.rollback(); } catch (Exception ignore) {}
            try { conn.setAutoCommit(true); } catch (Exception ignore) {}
            try { conn.close(); } catch (Exception ignore) {}
        }
        for (Connection connection : connections ) {
            try { connection.rollback(); } catch (Exception ignore) {}
            try { connection.setAutoCommit(true); } catch (Exception ignore) {}
            try { connection.close(); } catch (Exception ignore) {}
        }
        %></pre><%
    }
    if ( true ) return;

%><%--
    Datasource: jdbc/sit
    Database:   user@ACTD
    Schema:     act

    sit_epay

    sit_epaydtl

    sit_epay_sequence

    case when data_type='VARCHAR2' then 'VARCHAR2(' || data_length || ')'
         when data_type='NUMBER' then 
                case when data_precision is not null then
                     case when data_scale = '0' then 'NUMBER(' || data_precision || ')'
                          else 'NUMBER(' || data_precision || ',' || data_scale || ')'
                     end
                     else 'NUMBER'
                end
         else data_type
    end
--%><%!
public class GetObjectSummary extends Thread {
    public GetObjectSummary() {}
    public GetObjectSummary(Connection connection, String objectName) {
        this.connection = connection;
        this.objectName = objectName;
    }

    Connection      connection  = null;
    String          objectName  = null;

    StringBuffer    buffer      = new StringBuffer();
    public String   summary() { return buffer.toString(); }
    public long     duration = 0;
    public void run() {
        long start = System.currentTimeMillis();
        try {
            buffer.append(String.format("<h4>%s</h4>", objectName));
            buffer.append(String.format("<div class=\"content\">%s</div>",
                                        getObjectInformation(connection,objectName)
                                        )
                        );
        } catch (Exception e) {
            buffer.append("Exception: " + e.toString());
        }
        duration = (System.currentTimeMillis() - start);
    }


%><%!
    public String nvl(String val) { return (val == null ? "" : val); }

    public String getObjectInformation(Connection conn, String objectName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuffer buffer = new StringBuffer();
        StringBuffer detailBuffer = new StringBuffer();

        long start = System.currentTimeMillis();
        buffer.append("Started: " + start + "\n");
        buffer.append("Connection: " + (conn == null ? "NULL" : "Defined") + "\n");
        try {
        buffer.append("Prepare\n");
            ps = conn.prepareStatement(
                      "select owner, object_name, subobject_name, "
                    + "       object_type, status, "
                    + "       to_char(created,'mm/dd/yy hh24:mi'), "
                    + "       to_char(last_ddl_time,'mm/dd/yy hh24:mi'), "
                    + "       owner||'.'||object_name "
                    + "  from all_objects o "
                    + " where (object_name=upper(?)"
                    + "         or owner||'.'||object_name=upper(?))"
                    + "   and object_type not in ('TABLE PARTITION') "
                    + " order by 2, 3 desc"
                    );
        buffer.append("Set\n");
            ps.setString(1, objectName);
            ps.setString(2, objectName);
        buffer.append("Execute\n");
            rs = ps.executeQuery();
        buffer.append("isBeforeFirst\n");
            if ( ! rs.isBeforeFirst() ) {
                buffer.append("No object information found for: " + objectName + "\n");
            } else {
                buffer.append(
                String.format("%-12.12s %-20.20s %-20.20s "
                            + "%-16.16s %-8.8s %-15.15s %-15.15s\n",
                            "Owner", "Name", "Sub-Object Name",
                            "Object Type", "Status", "Created", "Last DDL"
                        )
                    );

                while ( rs.next() ) {
                    buffer.append(
                    String.format("%-12.12s %-20.20s %-20.20s "
                                + "%-16.16s %-8.8s %-15.15s %-15.15s\n",

                                rs.getString(1),
                                rs.getString(2),
                                nvl(rs.getString(3)),
                                rs.getString(4),
                                rs.getString(5),
                                rs.getString(6),
                                rs.getString(7)
                            )
                        );

                    if ( "TABLE".equals(rs.getString("object_type")) )
                        detailBuffer.append("<h3>Table: " + rs.getString(8) + "</h3><div class='content'>" + getTableSummary(conn,rs.getString(8)) + "</div>");
                    if ( "SEQUENCE".equals(rs.getString("object_type")) )
                        detailBuffer.append("<h3>Sequence: " + rs.getString(8) + "</h3><div class='content'>" + getSequenceSummary(conn,rs.getString(8)) + "</div>");
                    if ( "SYNONYM".equals(rs.getString("object_type")) )
                        detailBuffer.append("<h3>Synonym: " + rs.getString(8).replaceAll("(^PUBLIC\\.)(.*)$","$2")
                                            + "</h3><div class='content'>" + getSynonymInformation(conn,rs.getString(8)) + "</div>");
                }
            }
        } catch (Exception exception) {
            buffer.append("\nException: " + exception.toString() + "\n");
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
            buffer.append("<h6> Duration: " + (System.currentTimeMillis()-start) + "</h6>");
        }
        buffer.append(detailBuffer.toString());

        return buffer.toString();
    }





	/** Returns the current schema name of the database connection
	 *  <p>
	 * @param connection an open database connection
	 * @return the schema name the connection is using
	 * @throws Exception if an error occurs retrieving the name
	 */
    public String getSchema(Connection connection) throws Exception {
        Statement stmt   = null;
        ResultSet rs     = null;
        String    schema = null;

        try {
            stmt = connection.createStatement();
            rs = stmt.executeQuery("select sys_context('userenv','current_schema') schema from dual");
            rs.next();
            schema = rs.getString("schema");
        } catch (Exception exception) {
            throw exception;
        } finally {
            if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
            if ( stmt != null ) { try { stmt.close(); } catch (Exception e) {} stmt = null; }
        }
        return schema;
    }
    public String getRoles(Connection connection) throws Exception {
        StringBuffer buffer = new StringBuffer();
        buffer.append(getRoles(connection,"PUBLIC"));
        buffer.append("    ");
        buffer.append(getRoles(connection,Connect.getUser(connection)));
        return buffer.toString();
    }
    public String getRoles(Connection connection, String username) throws Exception {
        PreparedStatement   ps      = null;
        ResultSet           rs      = null;
        StringBuffer        buffer  = new StringBuffer();

        try {
            ps = connection.prepareStatement(
                        "select granted_role from user_role_privs where username=upper(?)"
                        );
            ps.setString(1,username);
            rs = ps.executeQuery();
            while ( rs.next() )  buffer.append(", " + rs.getString("granted_role"));
            buffer.replace(0,2,"");
            buffer.insert(0, username + ": ");
        } catch (Exception exception) {
            return exception.toString(); //throw exception;
        } finally {
            if ( rs != null ) { try { rs.close(); } catch (Exception e) {} rs = null; }
            if ( ps != null ) { try { ps.close(); } catch (Exception e) {} ps = null; }
        }

        return buffer.toString();
    }

    public String xgetRoles(Connection conn) throws Exception {
        StringBuffer buffer = new StringBuffer();
        String [] roles = Connect.getRoles(conn);
        for ( String role : roles ) buffer.append(", " + role);
        buffer.replace(0,2,"");
        return buffer.toString();
    }

    /*************************************************************
     ** Tables
     *************************************************************/
    public String getTableSummary(Connection conn, String tableName) {
        StringBuffer buffer = new StringBuffer();

        buffer.append(String.format("<h5>Table %s Columns</h5>", tableName));
        try {
            buffer.append(getTableColumns(conn,tableName));
        } catch (Exception exception) {
            buffer.append("Exception: " + exception.toString() + "\n");
        }

        buffer.append(String.format("<h5>Table %s Accessibility</h5>", tableName));
        try {
            buffer.append("Selectable: " + isTableSelectable(conn,tableName) + "\n");
            buffer.append("Updatable:  " + isTableUpdatable(conn,tableName) + "\n");
        } catch (Exception exception) {
            buffer.append("Exception: " + exception.toString() + "\n");
        }

        buffer.append(String.format("<h5>Table %s Synonyms</h5>", tableName));
        try {
            buffer.append(getSynonyms(conn,tableName));
        } catch (Exception exception) {
            buffer.append("Exception: " + exception.toString() + "\n");
        }

        buffer.append(String.format("<h5>Table %s Partitions</h5>", tableName));
        try {
            buffer.append(getTablePartitions(conn,tableName));
        } catch (Exception exception) {
            buffer.append("Exception: " + exception.toString() + "\n");
        }

        return buffer.toString();
    }
    public String isTableSelectable(Connection conn, String tableName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;

        long start = System.currentTimeMillis();
        try { 
            if ( tableName != null ) tableName = tableName.replaceAll("[^A-Za-z0-9_\\.]","");
            ps = conn.prepareStatement("select count(*) from " + tableName);
            rs = ps.executeQuery();
            rs.next();
        } catch (Exception exception) {
            return ("false: " + exception.toString());
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
        }

        return "true";
    }
    public String isTableUpdatable(Connection conn, String tableName) throws Exception {
        PreparedStatement ps = null;

        long start = System.currentTimeMillis();
        try { 
            if ( tableName != null ) tableName = tableName.replaceAll("[^A-Za-z0-9_\\.]","");
            ps = conn.prepareStatement(
                      "update " + tableName
                    + "   set client_id=client_id "
                    + " where client_id = -9999 and rownum < 0"
                    );
            ps.executeUpdate();
        } catch (Exception exception) {
            return ("false: " + exception.toString());
        } finally {
            try { ps.close(); } catch (Exception ignore) {}
        }

        return "true";
    }
    public String getTableColumns(Connection conn, String tableName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuffer buffer = new StringBuffer();

        long start = System.currentTimeMillis();
        try {
            ps = conn.prepareStatement(
                          "select column_name, nullable, data_default, "
                        + "       case when data_type='VARCHAR2' then 'VARCHAR2(' || data_length || ')' "
                        + "                when data_type='NUMBER' then  "
                        + "                       case when data_precision is not null then "
                        + "                            case when data_scale = '0' then 'NUMBER(' || data_precision || ')' "
                        + "                                 else 'NUMBER(' || data_precision || ',' || data_scale || ')' "
                        + "                            end "
                        + "                            else 'NUMBER' "
                        + "                       end "
                        + "                else data_type "
                        + "           end as \"type\", "
                        + "       column_id "
                        + "  from all_tab_columns  "
                        + " where table_name=? "
                        + "    or owner||'.'||table_name=upper(?)"
                        + " order by column_id asc "
                    );
            ps.setString(1, tableName);
            ps.setString(2, tableName);
            rs = ps.executeQuery();
            if ( ! rs.isBeforeFirst() ) {
                buffer.append("No column information found for: " + tableName + "\n");
            } else {
                buffer.append(
                String.format("%-20.20s %-15.15s %-8.8s %s\n",
                            "Column", "Type", "Nullable", "Default"
                        )
                    );

                // Handles oracle widememo column type
                Map widememoConversionMap = new Hashtable();
                widememoConversionMap.put("oracle.jdbc.driver.T4CLongAccessor",
                                    Class.forName("java.lang.String"));

                while ( rs.next() ) {
                    Object obj = rs.getObject("data_default",widememoConversionMap);
                    String defaultValue = (obj == null ? null : obj.toString());

                    buffer.append(
                        String.format("%-20.20s %-15.15s %-4.4s%-4.4s %s\n",
                                rs.getString("column_name"),
                                rs.getString("type"),
                                "",
                                rs.getString("nullable"),
                                nvl(defaultValue)
                            )
                        );
                }
            }
        } catch (Exception exception) {
            buffer.append("\nException: " + exception.toString() + "\n");
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
            buffer.append("<h6> Duration: " + (System.currentTimeMillis()-start) + "</h6>");
        }

        return buffer.toString();
    }
    public String getTablePartitions(Connection conn, String tableName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuffer buffer = new StringBuffer();

        long start = System.currentTimeMillis();
        try {
            ps = conn.prepareStatement(
                      "select owner, object_name, subobject_name, "
                    + "       object_type, status, "
                    + "       to_char(created,'mm/dd/yy hh24:mi'), "
                    + "       to_char(last_ddl_time,'mm/dd/yy hh24:mi'), "
                    + "       high_value "
                    + "  from all_objects o "
                    + "       left outer join all_tab_partitions p on "
                            + " (p.table_owner=o.owner "
                            + "  and p.table_name=o.object_name "
                            + "  and p.partition_name=o.subobject_name "
                            + ") "
                    + " where (object_name=upper(?)"
                    + "         or owner||'.'||object_name=upper(?))"
                    + "   and object_type = 'TABLE PARTITION' "
                    + " order by p.partition_position, 2, 3 desc"
                    );
            ps.setString(1, tableName);
            ps.setString(2, tableName);
            rs = ps.executeQuery();
            if ( ! rs.isBeforeFirst() ) {
                buffer.append("No partition information found for: " + tableName + "\n");
            } else {
                buffer.append(
                String.format("%-20.20s "
                            + "%-8.8s %-15.15s %-15.15s %12.12s\n",
                            "Partition Name",
                            "Status", "Created", "Last DDL",
                            "High Value"
                        )
                    );

                while ( rs.next() ) {
                    buffer.append(
                    String.format("%-20.20s "
                                + "%-8.8s %-15.15s %-15.15s %12.12s\n",

                                nvl(rs.getString(3)),
                                rs.getString(5),
                                rs.getString(6),
                                rs.getString(7),
                                nvl(rs.getString(8))
                            )
                        );
                }
            }
        } catch (Exception exception) {
            buffer.append("\nException: " + exception.toString() + "\n");
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
            buffer.append("<h6> Duration: " + (System.currentTimeMillis()-start) + "</h6>");
        }

        return buffer.toString();
    }

    /*************************************************************
     ** Synonyms
     *************************************************************/
    public String getSynonyms(Connection conn, String synonymName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuffer buffer = new StringBuffer();

        long start = System.currentTimeMillis();
        try {
            ps = conn.prepareStatement(
                      "select s.owner, s.synonym_name, s.table_owner, "
                    + "       s.table_name, status, "
                    + "       to_char(created,'mm/dd/yy hh24:mi'), "
                    + "       to_char(last_ddl_time,'mm/dd/yy hh24:mi') "
                    + "  from all_objects o "
                    + "       join all_synonyms s on "
                            + " (s.owner=o.owner "
                            + "  and s.synonym_name=o.object_name "
                            + ") "
                    + " where (s.table_name=upper(?)"
                    + "         or s.table_owner||'.'||s.table_name=upper(?))"
                    + "   and o.object_type = 'SYNONYM' "
                    + " order by 1, 2, 3, 4"
                    );
            ps.setString(1, synonymName);
            ps.setString(2, synonymName);
            rs = ps.executeQuery();
            if ( ! rs.isBeforeFirst() ) {
                buffer.append("No synonym information found for: " + synonymName + "\n");
            } else {
                buffer.append(
                String.format("%-12.12s %-20.20s %-12.12s %-20.20s "
                            + "%-8.8s %-15.15s %-15.15s\n",
                            "Owner", "Synonym",
                            "Table Owner", "Table Name",
                            "Status", "Created", "Last DDL"
                        )
                    );

                while ( rs.next() ) {
                    buffer.append(
                    String.format("%-12.12s %-20.20s %-12.12s %-20.20s "
                                + "%-8.8s %-15.15s %-15.15s\n",
                                nvl(rs.getString(1)),
                                nvl(rs.getString(2)),
                                nvl(rs.getString(3)),
                                nvl(rs.getString(4)),
                                rs.getString(5),
                                rs.getString(6),
                                rs.getString(7)
                            )
                        );
                }
            }
        } catch (Exception exception) {
            buffer.append("\nException: " + exception.toString() + "\n");
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
            buffer.append("<h6> Duration: " + (System.currentTimeMillis()-start) + "</h6>");
        }

        return buffer.toString();
    }

    public String getSynonymInformation(Connection conn, String synonymName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuffer buffer = new StringBuffer();

        long start = System.currentTimeMillis();
        try {
            buffer.append(String.format("<h5>Synonym %s Reference</h5>", synonymName));

            ps = conn.prepareStatement(
                      "select s.owner, s.synonym_name, s.table_owner, "
                    + "       s.table_name, status, "
                    + "       to_char(created,'mm/dd/yy hh24:mi'), "
                    + "       to_char(last_ddl_time,'mm/dd/yy hh24:mi') "
                    + "  from all_objects o "
                    + "       join all_synonyms s on "
                            + " (s.owner=o.owner "
                            + "  and s.synonym_name=o.object_name "
                            + ") "
                    + " where (s.synonym_name=upper(?)"
                    + "         or s.owner||'.'||s.synonym_name=upper(?))"
                    + "   and o.object_type = 'SYNONYM' "
                    + " order by 1, 2, 3, 4"
                    );
            ps.setString(1, synonymName);
            ps.setString(2, synonymName);
            rs = ps.executeQuery();
            if ( ! rs.isBeforeFirst() ) {
                buffer.append("No synonym information found for: " + synonymName + "\n");
            } else {
                buffer.append(
                    String.format("%-12.12s %-20.20s %-12.12s %-20.20s "
                            + "%-8.8s %-15.15s %-15.15s\n",
                            "Owner", "Synonym",
                            "Table Owner", "Table Name",
                            "Status", "Created", "Last DDL"
                        )
                    );

                while ( rs.next() ) {
                    buffer.append(
                    String.format("%-12.12s %-20.20s %-12.12s %-20.20s "
                                + "%-8.8s %-15.15s %-15.15s\n",
                                nvl(rs.getString(1)),
                                nvl(rs.getString(2)),
                                nvl(rs.getString(3)),
                                nvl(rs.getString(4)),
                                rs.getString(5),
                                rs.getString(6),
                                rs.getString(7)
                            )
                        );
                }
            }
        } catch (Exception exception) {
            buffer.append("\nException: " + exception.toString() + "\n");
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
            buffer.append("<h6> Duration: " + (System.currentTimeMillis()-start) + "</h6>");
        }

        return buffer.toString();
    }


    /*************************************************************
     ** Sequences
     *************************************************************/

    public String getSequenceSummary(Connection conn, String sequenceName) {
        StringBuffer buffer = new StringBuffer();

        buffer.append(String.format("<h5>Sequence %s Settings</h5>", sequenceName));
        try {
            buffer.append(getSequenceSettings(conn,sequenceName));
        } catch (Exception exception) {
            buffer.append("Exception: " + exception.toString() + "\n");
        }
        buffer.append(String.format("<h5>Sequence %s Accessibility</h5>", sequenceName));
        try {
            buffer.append("Selectable: " + isSequenceSelectable(conn,sequenceName) + "\n");
        } catch (Exception exception) {
            buffer.append("Exception: " + exception.toString() + "\n");
        }

        buffer.append(String.format("<h5>Sequence %s Synonyms</h5>", sequenceName));
        try {
            buffer.append(getSynonyms(conn,sequenceName));
        } catch (Exception exception) {
            buffer.append("Exception: " + exception.toString() + "\n");
        }


        return buffer.toString();
    }
    public String isSequenceSelectable(Connection conn, String sequenceName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;

        long start = System.currentTimeMillis();
        try {
            if ( sequenceName != null ) sequenceName = sequenceName.toUpperCase().replaceAll("[^A-Za-z0-9_\\.]","");
            ps = conn.prepareStatement("select " + sequenceName + ".currval from dual");
            rs = ps.executeQuery();
            rs.next();
        } catch (Exception exception) {
            if ( ! exception.getMessage().startsWith("ORA-08002: ") )
            return ("false: " + exception.toString());
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
        }

        return "true";
    }
    public String getSequenceSettings(Connection conn, String sequenceName) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuffer buffer = new StringBuffer();

        long start = System.currentTimeMillis();
        try {
            ps = conn.prepareStatement(
                          "select sequence_owner, sequence_name, "
                        + "       min_value, max_value, increment_by, "
                        + "       last_number "
                        + "  from all_sequences  "
                        + " where sequence_name=? "
                        + "    or sequence_owner||'.'||sequence_name=? "
                        + " order by sequence_owner, sequence_name "
                    );
            ps.setString(1, sequenceName);
            ps.setString(2, sequenceName);
            rs = ps.executeQuery();
            if ( ! rs.isBeforeFirst() ) {
                buffer.append("No setting information found for: " + sequenceName + "\n");
            } else {
                buffer.append(
                    String.format("%-12.12s %-20.20s %9.9s %9.9s %9.9s %9.9s\n",
                            "Owner", "Name", 
                            "Minimum", "Maximum", "Increment",
                            "Current"
                        )
                    );

                while ( rs.next() ) {
                    buffer.append(
                        String.format("%-12.12s %-20.20s %9.9s %9.9s %9.9s %9.9s\n",
                                rs.getString(1),
                                rs.getString(2),
                                rs.getString(3),
                                rs.getString(4),
                                rs.getString(5),
                                rs.getString(6)
                            )
                        );
                }
            }
        } catch (Exception exception) {
            buffer.append("\nException: " + exception.toString() + "\n");
        } finally {
            try { rs.close(); } catch (Exception ignore) {}
            try { ps.close(); } catch (Exception ignore) {}
            buffer.append("<h6> Duration: " + (System.currentTimeMillis()-start) + "</h6>");
        }

        return buffer.toString();
    }

}
%>
