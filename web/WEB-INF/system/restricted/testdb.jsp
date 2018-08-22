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
        <title>Deployemnt Information</title>
        <style>
        body { padding-top: 60px; } 
        h1 { font-family: "Arial Narrow"; }
        h4 { margin: 5px; margin-bottom:-10px;  padding: 0px; font-family: "Arial Narrow"; }
        div { display: inline-block; }
        </style>
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

    <h1> System Information </h1>
    <pre>
    <h4> Application Instance Properties </h4>
    <%= String.format("%-25s  %s", "Server Info:", application.getServerInfo()) %> 
    <%= String.format("%-25s  %s", "Instance Path:", application.getRealPath("")) %> 

    <%= String.format("%-25s  %d   %s", "Session Timeout:", 
                        session.getMaxInactiveInterval(),
                        String.format("(%02d:%02d minutes)",
                                        session.getMaxInactiveInterval()/60, 
                                        session.getMaxInactiveInterval()%60
                                        )
                        ) %>

    <h4> Java Properties </h4>
    <%= String.format("%-25s  %s", "java.home:", System.getProperties().getProperty("java.home")) %>
    <%= String.format("%-25s  %s", "java.version:", System.getProperties().getProperty("java.version")) %>
    <%= String.format("%-25s  %s", "java.class.version:", System.getProperties().getProperty("java.class.version")) %>

    <%= String.format("%-25s  %s", "java.runtime.version:", System.getProperties().getProperty("java.runtime.version")) %>

    <%= String.format("%-25s  %s", "java.library.path:", System.getProperties().getProperty("java.library.path").replaceAll(";",String.format(";\n%29s  ",""))) %>

    <h4> JNDI Datasources </h4>
    <div><%= listJndiDatasources() %></div>

<% try {
    JDBCResource x = new JDBCResource("jdbc/goomba");
    x.run();
    %><h3> Goomba</h3><div><%= x.toString() %></div><%
} catch (Exception e) {
    %><li> Exception: <%= e.toString() %><%
}
%>
    </pre>




    </body>
</html>
<%!
Class contextClass = javax.naming.Context.class;
String listJndiDatasources() {
    StringBuffer buffer = new StringBuffer();

    try {
        ArrayList jdbcList = new ArrayList();

        InitialContext ctx = new InitialContext();
        NamingEnumeration<NameClassPair> list = ctx.list("jdbc");
        while (list.hasMore()) {
            NameClassPair ncp = list.next();
            if ( ncp.getName().indexOf("__") >= 0 ) continue;

            JDBCResource jdbcResource = new JDBCResource(String.format("%s/%s","jdbc",ncp.getName()));
            jdbcList.add(jdbcResource);
            jdbcResource.start();
        }

        if ( jdbcList.size() > 0 ) {
            JDBCResource [] jdbcResources = (JDBCResource[]) jdbcList.toArray(new JDBCResource[0]);
            for ( JDBCResource jdbcResource : jdbcResources ) {
                jdbcResource.join();
                buffer.append(jdbcResource.toString() + "\n\n");
            }
        }
    } catch (Exception exception) {
        buffer.append("->Exception: " + exception.toString() + "\n");
    }

    return buffer.toString();
}
class JDBCResource extends Thread {
    public JDBCResource(String jndiName) {
        this.jndiName = jndiName;
    }
    public String       jndiName    = null;
    public String       dbName      = null;
    public Exception    exception   = null;

    public String       url                 = null;
    public String       userName            = null;
    public String       dbProductVersion    = null;
    public String       jdbcDriver         = null;
    public String       driverName          = null;

    public String toString() {
        return (exception == null ? String.format("%-25s %s\n%25s %-15s %-10s %s\n",
                                                    jndiName, dbProductVersion,
                                                    "", dbName, userName, url
                                                    )
                                  : String.format("%-25s %s\n", jndiName, exception)
                                  );
    }


    public void run() {
        try ( Connection con=((DataSource)(new InitialContext()).lookup(jndiName)).getConnection(); ) {
            DatabaseMetaData meta = con.getMetaData();
            url = meta.getURL();
            userName = meta.getUserName();
            dbProductVersion = meta.getDatabaseProductVersion().replaceAll("\\n",String.format("\n%25s ",""));
            jdbcDriver = String.format("%d.%d", meta.getJDBCMajorVersion(), meta.getJDBCMinorVersion());
            driverName = String.format("%s v%d.%d (%s)", meta.getDriverName(), meta.getDriverMajorVersion(), meta.getDriverMinorVersion(), meta.getDriverVersion());

            try ( Statement  stmt=con.createStatement();
                  ResultSet rs = stmt.executeQuery("select global_name, user from global_name"); ) {
                rs.next();
                dbName = rs.getString("global_name");
            }
        } catch (Exception exception) {
            this.exception = exception;
        }
    }
}
%><%!

%>