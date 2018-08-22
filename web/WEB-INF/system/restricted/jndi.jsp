<%@ page import="java.util.*,java.sql.*,javax.sql.*,javax.naming.*" 
%><%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");
%><!DOCTYPE html>
<%@ page contentType="text/html;charset=windows-1252"%>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252"/>
        <title>Deployement Information</title>
        <script>
            // Return user to the default page by pressing ^[home] ([home] is key code: 36)
            document.addEventListener("keyup", (event) => {
                const keyName = event.key;
                const ctrlKeyPressed = event.ctrlKey;
                const altKeyPressed = event.altKey;
                if ( ctrlKeyPressed && altKeyPressed && keyName == "Home" ) {
                    var parser = location;
                    location = parser.origin + parser.pathname.replace(/(\/[^\/]*\/[^\/]*\/).*/,"$1default.jsp");
                    return;
                }
            }, false);
        </script>
    <style>
        body { padding-top: 60px; padding-bottom: 100px; } 
        .commandHeader { position: fixed; z-index: 1000; top: 0px; left: 0px; right: 0px; height: 50px; background-color: #2f2f2f; font-size: 12px; }
        .commandHeader a { display: inline-block; padding: 10px 15px; font-size: 1.1rem; text-decoration: none; color: white; }
        .commandHeader a:hover { text-decoration: underline; color: lightblue; }
        .alternateFiles button {
                padding:5px 0; width: 100px; cursor: pointer; border-radius: 6px;
                font-size:0.8rem; font-weight: normal; margin: 4px 5px;
                text-transform:uppercase;
                letter-spacing:.1em;
                background: #1ab188;
                transition:all.5s ease;
                -webkit-appearance: none;
        }
    </style>
</head>
<body>
    <div class="commandHeader">
        <a href="<%= request.getContextPath() %>/restricted/default.jsp"> &#11148; Return </a>
    </div>

    <h4> JNDI Context </h4>
    <pre><%= listContext("") %></pre>

    <% if ( true ) { %>
        <h4> Context Class </h4>
        <pre> webLogic same object as context:  <%= webLogicContextClass == contextClass %></pre>
        <pre> webLogic assignable from context: <%= webLogicContextClass.isAssignableFrom(contextClass) %></pre>
        <pre> context assignable from webLogic: <%= contextClass.isAssignableFrom(webLogicContextClass) %></pre>
    <% } %>

</body>
</html>
<%!
Class contextClass = javax.naming.Context.class;
Class webLogicContextClass = contextClass;
{ try { webLogicContextClass = Class.forName("weblogic.jndi.internal.ServerNamingNode"); } catch (Exception ignore) {} }
//Class webLogic     = weblogic.jndi.internal.ServerNamingNode.class;


String listContext(String context) {
    StringBuffer buffer = new StringBuffer();

    try {
        ArrayList jdbcList = new ArrayList();

        InitialContext ctx = new InitialContext();
        NamingEnumeration<NameClassPair> list = ctx.list(context);
        while (list.hasMore()) {
            NameClassPair ncp = list.next();
            //if ( ncp.getName().indexOf("__") >= 0 ) continue;
            try {
                Class nodeClass = Class.forName(ncp.getClassName());
                if ( contextClass.isAssignableFrom(nodeClass) || webLogicContextClass.isAssignableFrom(nodeClass) ){
                    buffer.append(context+"/"+ncp.getName()+"\n");
                    buffer.append("<div style='margin-left:55px;margin-top:0px;margin-bottom:0px;'>");
                    buffer.append(listContext((context.length() > 0 ? context+"/" : "")+ncp.getName()));
                    buffer.append("</div>\n");
                } else {
                    if ( ! "jdbc".equals(context) ) {
                        buffer.append(context+"/"+ncp.getName()+"\n");
                        buffer.append("\t"+ncp.getClassName()+"\n");
                    } else {
                        if ( ncp.getName().indexOf("__") >= 0 ) continue;
                        JDBCResource jdbcResource = new JDBCResource(String.format("%s/%s",context,ncp.getName()));
                        jdbcList.add(jdbcResource);
                        jdbcResource.start();
                    }
                }
            } catch (ClassNotFoundException exception) {
                buffer.append(String.format("%s - class not found: %s\n",
                                            ncp.getName(),
                                            ncp.getClassName())
                                );
                continue;
            }
        }

        if ( jdbcList.size() > 0 ) {
            JDBCResource [] jdbcResources = (JDBCResource[]) jdbcList.toArray(new JDBCResource[0]);
            for ( JDBCResource jdbcResource : jdbcResources ) {
                jdbcResource.join();
                if ( jdbcResource.exception != null ) {
                    buffer.append(jdbcResource.jndiName+"\n");
                    buffer.append(String.format("\t%s\n\n",jdbcResource.exception.toString()));
                } else {
                    buffer.append(String.format("%-25s %-20s %s\n\n",
                                                jdbcResource.jndiName,jdbcResource.dbName,jdbcResource.dbUser
                                                )
                                    );
                }
            }
        }
    } catch (Exception exception) {
        buffer.append("->Exception: " + exception.toString() + "\n");
    }
    buffer.append("</div>\n");

    return buffer.toString();
}
class JDBCResource extends Thread {
    public JDBCResource(String jndiName) {
        this.jndiName = jndiName;
    }
    public String       jndiName    = null;
    public String       dbName      = null;
    public String       dbUser      = null;
    public Exception    exception   = null;
    public void run() {
        try (Connection conn=((DataSource)(new InitialContext()).lookup(jndiName)).getConnection();
             Statement  stmt=conn.createStatement();
            ) {
            try ( ResultSet rs = stmt.executeQuery("select global_name, user from global_name"); ) {
                rs.next();
                dbName = rs.getString("global_name");
                dbUser = rs.getString("user");
            }
        } catch (Exception exception) {
            this.exception = exception;
        }
    }
}
%><%!

%>