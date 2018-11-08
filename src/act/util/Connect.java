package act.util;
import java.util.*;
import java.sql.*;
import javax.naming.InitialContext;
import javax.sql.DataSource;


/**
 * Provides convenience methods to open database connections and retrieve basic connection information.
 * <p>
 * This class provides four main database function groups:
 * <ul>
 * <li> Open database connection, either by JNDI name or JDBC:thin connection information
 * <li> Returns the database name (from global__name) of the connection
 * <li> Returns whether the database connection user has an specific role granted (from user_role_privs table)
 * <li> Returns a list of roles granted to the the database connection user (from user_role_privs table)
 * </ul>
 * The method function groups support calls with the use of a JNDI data source name using the default user and
 * a JNDI data source name with specific user/password. All method function groups, with the exception of the 
 * open connection function group, also allow the use of an existing open java.sql.Connection.
 * 
 * <p>
 * <pre>
 * Connection conn = null;
 * PreparedStatement ps = null;
 * ResultSet rs = null;
 * Statement stmt = null;
 * try {
 *       try {
 *              conn = Connect.open("jdbc/development");
 *       } catch (Exception e) {
 *              Connect.extend(e,"Failed to open database connection");
 *       }
 *
 *       String dbName = null;
 *       try {
 *              dbName = Connect.getName(conn);
 *       } catch (Exception e) {
 *              Connect.extend(e,"Failed to retrieve database name");
 *       }
 *
 *       try {
 *              ps = conn.prepareStatment("select count(*) from dual");
 *              rs = ps.executeQuery();
 *       } catch (Exception e) {
 *              Connect.extend(e,"Failed to retrieve data");
 *       } finally {
 *              try { rs.close(); } catch (Exception e) {} rs = null;
 *              try { ps.close(); } catch (Exception e) {} ps = null;
 *       }
 *
 *       ... other code ...
 *
 * } catch (Exception e) {
 *       log.error(e);
 * } finally {
 *       try { conn.close(); } catch (Exception e) {} conn = null;
 * }
 * </pre>
 */
public class Connect {
	public Connect() { super(); }


	/** Opens a new database connection to the specified data source.
	 * @param datasource a jdbc data source or JNDI named data source 
	 * @return a new Connection to the database specified by data source using the default user
	 * @throws Exception if an error occurs opening the connection
	 */
	public static Connection open(String datasource) throws Exception {
		return open(datasource,null,null);
	}

	/** Opens a new database connection to the specified data source connecting as the specified user.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @param user user to connect as
	 * @param password user's password to connect
	 * @return a new Connection to the database specified by data source
	 * @throws Exception if an error occurs opening the connection
	 */
	public static Connection open(String datasource, String user, String password) throws Exception {
		InitialContext context         = null;
		Connection     connection      = null;
		try {
			if ( datasource == null ) throw new SQLException("Data source not specified");

			if ( datasource.startsWith("jdbc:") ) {
				try {
					Class.forName("oracle.jdbc.driver.OracleDriver"); 
				} catch ( ClassNotFoundException e ) {
					throw new SQLException("Unable to load database driver");
				}

				if ( user == null ) {
					connection = java.sql.DriverManager.getConnection(datasource,"sit_inq","texas1");
				} else {
					connection = java.sql.DriverManager.getConnection(datasource, user, password);
				}
			} else {
				context        = new InitialContext();
				if ( user == null ) {
					connection = ((DataSource) context.lookup(datasource)).getConnection();
				} else {
					connection = ((DataSource) context.lookup(datasource)).getConnection(user,password);
				}
			}

			if ( connection == null ) throw new SQLException("Unable to open connection");
		} catch (Exception e) {
			extend(e,"Opening database connection");
		} finally {
			context = null;
		}
		return connection;
	}

	/** Returns the name of the database as defined in the global_name table in the database.
	 *  <p>
     *  A connection to the database is temporarily created to retrieve the name.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @return the name of the database specified by data source
	 * @throws Exception if an error occurs opening the connection or retrieving the name
	 */
	public static String getName(String datasource) throws Exception {
		return getName(datasource,null,null);
	}

	/** Returns the name of the database as defined in the global_name table in the database.
	 *  <p>
	 *  A connection to the database is temporarily created to retrieve the name.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @param user user to connect as
	 * @param password user's password to connect
	 * @return the name of the database specified by data source
	 * @throws Exception if an error occurs opening the connection or retrieving the name
	 */
	public static String getName(String datasource, String user, String password) throws Exception {
		Connection connection = null;
		String name = null;
		try {
			connection = (user != null ? open(datasource,user,password) : open(datasource));
			name = getName(connection);
		} catch (Exception e) {
			throw e;
		} finally {
			try { connection.close(); } catch(Exception ee) {} connection = null; 
		}
		return name;
	}

	/** Returns the name of the database as defined in the global_name table in the database
	 * @param connection an open database connection
	 * @return the name of the database connected to
	 * @throws Exception if an error occurs retrieving the name
	 */
	public static String getName(Connection connection) throws Exception {
		Statement stmt = null;
		ResultSet rs   = null;
		String    name = null;

		try {
			stmt = connection.createStatement();
			rs = stmt.executeQuery("select global_name from global_name");
			rs.next();
			name = rs.getString(1);
		} catch (Exception e) {
			extend(e,"Retrieving database name");
		} finally {
			if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
			if ( stmt != null ) { try { stmt.close(); } catch (Exception e) {} stmt = null; }
		}
		return name;
	}

	/** Returns the user name of the database connection user.
	 *  <p>
     *  A connection to the database is temporarily created to retrieve the user name.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @return the name of the database specified by data source
	 * @throws Exception if an error occurs opening the connection or retrieving the name
	 */
	public static String getUser(String datasource) throws Exception {
		Connection connection = null;
		String name = null;
		try {
			connection = open(datasource);
			name = getName(connection);
		} catch (Exception e) {
			throw e;
		} finally {
			try { connection.close(); } catch (Exception e) {} connection = null;
		}
		return name;
	}

	/** Returns the user name of the database connection user.
	 *  <p>
	 * @param connection an open database connection
	 * @return the name of the database connected to
	 * @throws Exception if an error occurs retrieving the name
	 */
	public static String getUser(Connection connection) throws Exception {
		Statement stmt = null;
		ResultSet rs   = null;
		String    name = null;

		try {
			stmt = connection.createStatement();
			rs = stmt.executeQuery("select user from dual");
			rs.next();
			name = rs.getString(1);
		} catch (Exception e) {
			extend(e,"Retrieve user name");
		} finally {
			if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
			if ( stmt != null ) { try { stmt.close(); } catch (Exception e) {} stmt = null; }
		}
		return name;
	}


	/** Returns whether the database connection use has been granted the specified database role.
	 *  <p>
	 *  User roles are determined by the granted_role column of the user_role_privs table.
	 *  <p>
     *  A connection to the database is temporarily created to determine whether the role has been granted or not.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @role  role name to checked whether it is granted or not
	 * @return true if the role has been granted to the user, false otherwise
	 * @throws Exception if an error occurs opening the connection or verifying the role
	 */
	public static boolean hasRole(String datasource, String role) throws Exception {
		return hasRole(datasource, null, null, role);
	}
	/** Returns whether the database connection use has been granted the specified database role.
	 *  <p>
	 *  User roles are determined by the granted_role column of the user_role_privs table.
	 *  <p>
     *  A connection to the database is temporarily created to determine whether the role has been granted or not.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @param user user to connect as
	 * @param password user's password to connect
	 * @role  role name to checked whether it is granted or not
	 * @return true if the role has been granted to the user, false otherwise
	 * @throws Exception if an error occurs opening the connection or verifying the role
	 */
	public static boolean hasRole(String datasource, String user, String password, String role) throws Exception {
		Connection connection    = null;
		boolean    hasRole = false;
		try {
			connection  = (user != null ? open(datasource,user,password) : open(datasource));
			hasRole = hasRole(connection, role);
		} catch (Exception e) {
			throw e;
		} finally {
			try { connection.close(); } catch(Exception ee) {} connection = null; 
		}
		return hasRole;
	}
	/** Returns whether the database connection use has been granted the specified database role.
	 *  <p>
	 *  User roles are determined by the granted_role column of the user_role_privs table.
     * @param connection an open database connection
	 * @role  role name to checked whether it is granted or not
	 * @return true if the role has been granted to the user, false otherwise
	 * @throws Exception if an error occurs opening the connection or verifying the role
	 */
	public static boolean hasRole(Connection connection, String role) throws Exception {
		PreparedStatement ps      = null;
		ResultSet         rs      = null;
		boolean           hasRole = false;

		try {
			ps = connection.prepareStatement("select count(*) from user_role_privs where username=user and granted_role=upper(?)");
			ps.setString(1,role);
			rs = ps.executeQuery();
			rs.next();
			hasRole = (rs.getInt(1) > 0);
		} catch (Exception e) {
			extend(e,"Check for role");
		} finally {
			if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
			if ( ps   != null ) { try { ps.close();   } catch (Exception e) {} ps   = null; }
		}
		return hasRole;
	}


	/** Returns a list of roles granted to the data source user.
	 *  <p>
	 *  User roles are retrieved from the granted_role column of the user_role_privs table.
	 *  <p>
     *  A connection to the database is temporarily created to retrieve the granted roles.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @return String array of roles granted to the data source user
	 * @throws Exception if an error occurs opening the connection or retrieving roles
	 */
	public static String [] getRoles(String datasource) throws Exception {
		return getRoles(datasource, null, null);
	}
	/** Returns a list of roles granted to the specified user.
	 *  <p>
	 *  User roles are retrieved from the granted_role column of the user_role_privs table.
	 *  <p>
     *  A connection to the database is temporarily created to retrieve the granted roles.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @param user user to connect as
	 * @param password user's password to connect
	 * @return String array of roles granted to the specified user
	 * @throws Exception if an error occurs opening the connection or retrieving roles
	 */
	public static String [] getRoles(String datasource, String user, String password) throws Exception {
		Connection connection    = null;
		String []  roles   = null;
		try {
			connection  = (user != null ? open(datasource,user,password) : open(datasource));
			roles = getRoles(connection);
		} catch (Exception e) {
			throw e;
		} finally {
			try { connection.close(); } catch(Exception ee) {} connection = null; 
		}
		return roles;
	}
	/** Returns a list of roles granted to the connection user.
	 *  <p>
	 *  User roles are retrieved from the granted_role column of the user_role_privs table.
	 *  <p>
     * @param connection an open database connection
	 * @return String array of roles granted to the specified user
	 * @throws Exception if an error occurs opening the connection or retrieving roles
	 */
	public static String [] getRoles(Connection connection) throws Exception {
		PreparedStatement ps      = null;
		ResultSet         rs      = null;
		ArrayList         roles   = new ArrayList();

		try {
			ps = connection.prepareStatement("select granted_role from user_role_privs where username=user order by granted_role");
			rs = ps.executeQuery();
			rs.next();
			roles.add(rs.getString(1));
		} catch (Exception e) {
			extend(e,"Retrieve roles");
		} finally {
			if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
			if ( ps   != null ) { try { ps.close();   } catch (Exception e) {} ps   = null; }
		}
		return (String []) roles.toArray(new String[0]);
	}


	/**Returns whether the user can log into the database successfully or not
	 * <p>
	 * A connection to the database is temporarily created to determine whether the user can log in or not
	 * @param datasource a jdbc data source or JNDI named data source
	 * @param user user to connect as
	 * @param password user's password to connect
	 * @return true if the user can log into the database
	 * @throws Exception if an error other than invalid user/password occurs opening the connection 
	 */
	public static boolean isDatabaseUser(String datasource, String user, String password) throws Exception {
		Connection connection    = null;
		boolean    isValidUser   = false;

		try {
			connection  = open(datasource,user,password);
			isValidUser = true;
		} catch (SQLException e) {
			// If not invalid user/password throw error
			if ( e.getMessage().indexOf("ORA-01017:") < 0 ) throw e;
		} finally {
			try { connection.close(); } catch(Exception ee) {} connection = null; 
		}
		return isValidUser;
	}
	/** Returns whether the specified database user has an Oracle account and has been granted the specified database role.
	 *  <p>
	 *  User roles are determined by the granted_role column of the user_role_privs table.
	 *  <p>
     *  A connection to the database is temporarily created to determine whether the role has been granted or not.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @param user user to connect as
	 * @param password user's password to connect
	 * @role  role name to checked whether it is granted or not
	 * @return true if the user is a valid database user and the role has been granted to the user, false otherwise
	 * @throws Exception if an error occurs opening the connection or verifying the role
	 */
	public static boolean isDatabaseUser(String datasource, String user, String password, String role) throws Exception {
		Connection connection    = null;
		boolean    isValidUser   = false;
		try {
			connection  = open(datasource,user,password);
			isValidUser = hasRole(connection, role);
		} catch (Exception e) {
			// If not invalid user/password throw error
			if ( e.getMessage().indexOf("ORA-01017:") < 0 ) throw e;
		} finally {
			try { connection.close(); } catch(Exception ee) {} connection = null; 
		}
		return isValidUser;
	}


	/** Returns the schema name of the database the user connects to.
	 *  <p>
	 *  A connection to the database is temporarily created to retrieve the schema name.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @return the schema name of the database connection specified by data source 
	 * @throws Exception if an error occurs opening the connection or retrieving the schema name
	 */
	public static String getSchema(String datasource) throws Exception {
		return getSchema(datasource,null,null);
	}

	/** Returns the schema name of the database the user connects to.
	 *  <p>
	 *  A connection to the database is temporarily created to retrieve the schema name.
	 * @param datasource a jdbc data source or JNDI named data source
	 * @param user user to connect as
	 * @param password user's password to connect
	 * @return the schema name of the database connection specified by data source the user connects to
	 * @throws Exception if an error occurs opening the connection or retrieving the schema name
	 */
	public static String getSchema(String datasource, String user, String password) throws Exception {
		Connection connection = null;
		String schema = null;
		try {
			connection = (user != null ? open(datasource,user,password) : open(datasource));
			schema = getSchema(connection);
		} catch (Exception e) {
			throw e;
		} finally {
			try { connection.close(); } catch(Exception ee) {} connection = null; 
		}
		return schema;
	}

	/** Returns the schema name of the database the connection is currently connected to.
	 * @param connection an open database connection
	 * @return the schema name of the current database connection 
	 * @throws Exception if an error occurs retrieving the schema name
	 */
	public static String getSchema(Connection connection) throws Exception {
		Statement stmt   = null;
		ResultSet rs     = null;
		String    schema = null;

		try {
			stmt = connection.createStatement();
			rs = stmt.executeQuery("select sys_context( 'userenv', 'current_schema' ) from dual");
			rs.next();
			schema = rs.getString(1);
		} catch (Exception e) {
			extend(e,"Retrieving database schema");
		} finally {
			if ( rs   != null ) { try { rs.close();   } catch (Exception e) {} rs   = null; }
			if ( stmt != null ) { try { stmt.close(); } catch (Exception e) {} stmt = null; }
		}
		return schema;
	}



	/** Throws a new exception of the same type with the provided message prefixed to the existing exception message.
	 *  <p>
	 *  A new exception is created of the same type as the specified exception. The exception message remains the
	 *  same but is prefixed by the user specified message. Useful to provide code location information in an exception.
	 *  <p>
	 *  Calling this function throws the new exception, it does not return the exception object.
	 *  <pre>
	 *       try {
	 *              ...
	 *       } catch (Exception e) {
	 *              Connect.extend(e,"Some additional message");
	 *       }
	 *  </pre>
     * @param e Exception to extend
	 * @param message message to prefix to existing exception message
	 * @throws Exception newly created exception of the same class type with the same exception message prefixed by the specified message
	 */
	public static void extend(Exception e, String message) throws Exception {
		throw (Exception) e.getClass().getConstructor(new Class[]{(new String()).getClass()}).newInstance((Object[])(new String[]{message + ". " + e.getMessage()}));
	}
}
