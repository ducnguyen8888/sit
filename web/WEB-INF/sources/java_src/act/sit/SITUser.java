package act.sit;

import act.util.Connect;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

import java.time.LocalDateTime;


public class SITUser
{
    public SITUser() {}
    public SITUser(String datasource, String clientId, String userName)
    {
        this(datasource, clientId, userName, null);
    }
    public SITUser(String datasource, String clientId, String userName, String pin)
    {
        this.datasource = datasource;
        this.clientId   = clientId;
        this.userName   = userName;
        this.pin        = pin;
    }

    public      StringBuilder   trace               = new StringBuilder();

    protected   String          failureReason       = null;

    protected   String          datasource          = null;
    protected   String          clientId            = null;

    protected   String          userName            = null;
    protected   String          pin                 = null;

    protected   String          userId              = null;
    protected   LocalDateTime   lastLoginTime       = null;


    protected   boolean         isLoggedIn          = false;
    protected   boolean         isValid             = false;
    protected   LocalDateTime   loginTime           = null;

    protected   boolean         isAdmin             = false;
    protected   boolean         isLocked            = false;
    protected   boolean         viewOnly            = false;

    protected   boolean         requiresPinChange   = false;
    protected   LocalDateTime   lastPinChangeTime   = null;
    protected   String          resetId             = null;

    public      String          name                = null;
    public      String          title               = null;
    public      String          address1            = null;
    public      String          address2            = null;
    public      String          city                = null;
    public      String          state               = null;
    public      String          zipcode             = null;
    public      String          phone               = null;
    public      String          email               = null;

    public      String          getDataSource()         { return datasource; }
    public      String          getClientId()           { return clientId; }
    public      String          getUserId()             { return userId; }
    public      String          getUserName()           { return userName; }

    public      String          getFailureReason()      { return failureReason; }

    public      boolean         isLoggedIn()            { return isValid && isLoggedIn; }
    public      boolean         isValid()               { return isValid; }
    public      LocalDateTime   getLoginTime()          { return loginTime; }
    public      LocalDateTime   getLastLoginTime()      { return lastLoginTime; }

    public      boolean         isAdmin()               { return isAdmin; }
    public      boolean         isLocked()              { return isLocked; }
    public      boolean         viewOnly()              { return viewOnly; }

    public      boolean         requiresPinChange()     { return requiresPinChange; }
    public      LocalDateTime   getLastPinChangeTime()  { return lastPinChangeTime; }
    public      String          getResetId()            { return resetId; }



    public      void    logout()
    {
        isValid = false;
        isLoggedIn = false;
        return;
    }

    public boolean login() throws Exception
    {
        isValid = false;
        isLoggedIn = false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "select userid, lastaccess, isAdmin, isLocked, reqpinchng, lastpinchng, reset_id, "
                                            + "       name, title, address1, address2, city, state, zipcode, phone, email "
                                            + "  from sit_users "
                                            + " where client_id=? and upper(username)=upper(?) "
                                            + "   and ( (length(pin) < 30 and upper(pin)=upper(?)) "
                                            + "        or pin = act_vit.sitwebutil.hashpin(client_id, username, ?) "
                                            + "       )",
                                            ResultSet.TYPE_SCROLL_SENSITIVE,
                                            ResultSet.CONCUR_UPDATABLE
                                            );
            )
        {
            ps.setString(1, clientId);
            ps.setString(2, userName);
            ps.setString(3, pin);
            ps.setString(4, pin);

            try ( ResultSet rs = ps.executeQuery(); )
            {
                if ( ! rs.next() )
                {
                    failureReason = "No user was found for the specified ID";
                }
                else
                {
                    isValid             = true;
                    loginTime           = LocalDateTime.now();

                    userId              = rs.getString("userid");
                    lastLoginTime       = (rs.getTimestamp("lastaccess") == null ? null : rs.getTimestamp("lastaccess").toLocalDateTime());

                    isAdmin             = "Y".equalsIgnoreCase(rs.getString("isadmin"));
                    isLocked            = "Y".equalsIgnoreCase(rs.getString("islocked"));
                    viewOnly            = "Y".equalsIgnoreCase(rs.getString("isadmin"));
                    requiresPinChange   = "Y".equalsIgnoreCase(rs.getString("reqpinchng")) || lastLoginTime == null;

                    lastPinChangeTime   = (rs.getTimestamp("lastpinchng") == null ? null : rs.getTimestamp("lastpinchng").toLocalDateTime());

                    resetId             = rs.getString("reset_id");

                    name                = rs.getString("name");
                    title               = rs.getString("title");
                    address1            = rs.getString("address1");
                    address2            = rs.getString("address2");
                    city                = rs.getString("city");
                    state               = rs.getString("state");
                    zipcode             = rs.getString("zipcode");
                    phone               = rs.getString("phone");
                    email               = rs.getString("email");

                    // If this is first time user has logged in force a PIN change
                    if ( lastLoginTime == null && ! "Y".equalsIgnoreCase(rs.getString("reqpinchng")) )
                    {
                        rs.updateString("reqpinchng", "Y");
                    }

                    rs.updateTimestamp("lastaccess", Timestamp.valueOf(loginTime));
                    rs.updateRow();
                }
            }
        }
        catch (Exception error)
        {
            failureReason = error.toString();
            throw error;
        }
        finally
        {
            isLoggedIn = isValid;
        }

        return isLoggedIn;
    }


    public boolean loadUserData() throws Exception
    {
        isValid = false;
        isLoggedIn = false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "select userid, lastaccess, isAdmin, isLocked, reqpinchng, lastpinchng, reset_id, "
                                            + "       name, title, address1, address2, city, state, zipcode, phone, email "
                                            + "  from sit_users "
                                            + " where client_id=? and upper(username)=upper(?) "
                                            + "   and ( (length(pin) < 30 and upper(pin)=upper(?)) "
                                            + "        or pin = act_vit.sitwebutil.hashpin(client_id, username, ?) "
                                            + "       )"
                                            );
            )
        {
            ps.setString(1, clientId);
            ps.setString(2, userName);
            ps.setString(3, pin);
            ps.setString(4, pin);

            try ( ResultSet rs = ps.executeQuery(); )
            {
                if ( ! rs.next() )
                {
                    failureReason = "No user was found for the specified ID";
                }
                else
                {
                    isValid             = true;
                    loginTime           = LocalDateTime.now();

                    userId              = rs.getString("userid");
                    lastLoginTime       = (rs.getTimestamp("lastaccess") == null ? null : rs.getTimestamp("lastaccess").toLocalDateTime());

                    isAdmin             = "Y".equalsIgnoreCase(rs.getString("isadmin"));
                    isLocked            = "Y".equalsIgnoreCase(rs.getString("islocked"));
                    requiresPinChange   = "Y".equalsIgnoreCase(rs.getString("reqpinchng")) || lastLoginTime == null;

                    lastPinChangeTime   = (rs.getTimestamp("lastpinchng") == null ? null : rs.getTimestamp("lastpinchng").toLocalDateTime());

                    resetId             = rs.getString("reset_id");

                    name                = rs.getString("name");
                    title               = rs.getString("title");
                    address1            = rs.getString("address1");
                    address2            = rs.getString("address2");
                    city                = rs.getString("city");
                    state               = rs.getString("state");
                    zipcode             = rs.getString("zipcode");
                    phone               = rs.getString("phone");
                    email               = rs.getString("email");
                }
            }
        }

        return isValid;
    }


    // Updates local contact information only, no database changes are made
    public SITUser setContact(SITUser user)
    {
        this.name                = user.name;
        this.title               = user.title;
        this.address1            = user.address1;
        this.address2            = user.address2;
        this.city                = user.city;
        this.state               = user.state;
        this.zipcode             = user.zipcode;
        this.phone               = user.phone;
        this.email               = user.email;

        return this;
    }

    public boolean updateContact() throws Exception
    {
        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "update sit_users "
                                            + "   set name=?, title=?, address1=?, address2=?, city=?, state=?, zipcode=?, phone=?, email=? "
                                            + " where client_id=? and userid=? and upper(username)=upper(?) "
                                            + "   and ( (length(pin) < 30 and upper(pin)=upper(?)) "
                                            + "        or pin = act_vit.sitwebutil.hashpin(client_id, username, ?) "
                                            + "       )"
                                            );
            )
        {
            ps.setString(1, name);
            ps.setString(2, title);
            ps.setString(3, address1);
            ps.setString(4, address2);
            ps.setString(5, city);
            ps.setString(6, state);
            ps.setString(7, zipcode);
            ps.setString(8, phone);
            ps.setString(9, email);

            ps.setString(10, clientId);
            ps.setString(11, userId);
            ps.setString(12, userName);
            ps.setString(13, pin);
            ps.setString(14, pin);

            return ps.executeUpdate() > 0;
        }
    }

    public boolean changePin(String newPin) throws Exception
    {
        return changePin(pin, newPin);
    }
    public boolean changePin(String pin, String newPin) throws Exception
    {
        boolean wasSuccessful = false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "update sit_users "
                                            + "   set pin=act_vit.sitwebutil.hashpin(client_id, username, ?), "
                                            + "       lastpinchng=sysdate, reqpinchng=null, reset_id=null "
                                            + " where client_id=? and userid=? and upper(username)=upper(?) "
                                            + "   and ( (length(pin) < 30 and upper(pin)=upper(?)) "
                                            + "        or pin = act_vit.sitwebutil.hashpin(client_id, username, ?) "
                                            + "       )"
                                            );
            )
        {
            ps.setString(1, newPin);

            ps.setString(2, clientId);
            ps.setString(3, userId);
            ps.setString(4, userName);
            ps.setString(5, pin);
            ps.setString(6, pin);

            if ( ps.executeUpdate() > 0 )
            {
                wasSuccessful       = true;
                pin                 = newPin;
                lastPinChangeTime   = LocalDateTime.now();
                requiresPinChange   = false;
                resetId             = null;
            }
        }

        return wasSuccessful;
    }

    public boolean resetPin(String resetId, String newPin) throws Exception
    {
        boolean wasSuccessful = false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "update sit_users "
                                            + "   set pin=act_vit.sitwebutil.hashpin(client_id, username, ?), "
                                            + "       lastpinchng=sysdate, reqpinchng=null, reset_id=null "
                                            + " where client_id=? and upper(username)=upper(?) "
                                            + "   and reset_id=?"
                                            );
            )
        {
            ps.setString(1, newPin);

            ps.setString(2, clientId);
            ps.setString(3, userName);
            ps.setString(4, resetId);

            if ( ps.executeUpdate() > 0 )
            {
                wasSuccessful       = true;
                pin                 = newPin;
                lastPinChangeTime   = LocalDateTime.now();
                requiresPinChange   = false;
                resetId             = null;
            }
        }

        return wasSuccessful;
    }

    public boolean updatePin(String newPin) throws Exception
    {
        boolean wasSuccessful = false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "update sit_users "
                                            + "   set pin=act_vit.sitwebutil.hashpin(client_id, username, ?), "
                                            + "       lastpinchng=sysdate, reqpinchng=null, reset_id=null "
                                            + " where client_id=? and userid=? and upper(username)=upper(?) "
                                            + "   and ( (length(pin) < 30 and upper(pin)=upper(?)) "
                                            + "        or pin = act_vit.sitwebutil.hashpin(client_id, username, ?) "
                                            + "       )"
                                            );
            )
        {
            ps.setString(1, newPin);

            ps.setString(2, clientId);
            ps.setString(3, userId);
            ps.setString(4, userName);
            ps.setString(5, pin);
            ps.setString(6, pin);

            if ( ps.executeUpdate() > 0 )
            {
                wasSuccessful       = true;
                pin                 = newPin;
                lastPinChangeTime   = LocalDateTime.now();
                requiresPinChange   = false;
                resetId             = null;
            }
        }

        return wasSuccessful;
    }


    public boolean lockAccount() throws Exception
    {
        return updateLockedAccountFlag("Y");
    }
    public boolean unlockAccount() throws Exception
    {
        return updateLockedAccountFlag(null);
    }
    protected boolean updateLockedAccountFlag(String flagValue) throws Exception
    {
        boolean wasSuccessful = false;

        if ( "Y".equalsIgnoreCase(flagValue) && isLocked ) return false;
        if ( ! "Y".equalsIgnoreCase(flagValue) && ! isLocked ) return false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "update sit_users "
                                            + "   set isLocked=? "
                                            + " where client_id=? and userid=? and upper(username)=upper(?) "
                                            + "   and ( (length(pin) < 30 and upper(pin)=upper(?)) "
                                            + "        or pin = act_vit.sitwebutil.hashpin(client_id, username, ?) "
                                            + "       )"
                                            );
            )
        {
            ps.setString(1, flagValue);

            ps.setString(2, clientId);
            ps.setString(3, userId);
            ps.setString(4, userName);
            ps.setString(5, pin);
            ps.setString(6, pin);

            if ( ps.executeUpdate() > 0 )
            {
                isLocked            = "Y".equalsIgnoreCase(flagValue);
            }
        }

        return wasSuccessful;
    }

    public boolean clearPinChangeRequired() throws Exception
    {
        return updatePinChangeRequiredFlag(null);
    }
    public boolean setPinChangeRequired() throws Exception
    {
        return updatePinChangeRequiredFlag("Y");
    }
    protected boolean updatePinChangeRequiredFlag(String flagValue) throws Exception
    {
        boolean wasSuccessful = false;

        if ( "Y".equalsIgnoreCase(flagValue) && requiresPinChange ) return false;
        if ( ! "Y".equalsIgnoreCase(flagValue) && ! requiresPinChange ) return false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "update sit_users "
                                            + "   set reqpinchng=? "
                                            + " where client_id=? and userid=? and upper(username)=upper(?) "
                                            + "   and ( (length(pin) < 30 and upper(pin)=upper(?)) "
                                            + "        or pin = act_vit.sitwebutil.hashpin(client_id, username, ?) "
                                            + "       )"
                                            );
            )
        {
            ps.setString(1, flagValue);

            ps.setString(2, clientId);
            ps.setString(3, userId);
            ps.setString(4, userName);
            ps.setString(5, pin);
            ps.setString(6, pin);

            if ( ps.executeUpdate() > 0 )
            {
                requiresPinChange   = "Y".equalsIgnoreCase(flagValue);
            }
        }

        return wasSuccessful;
    }


    public boolean generateResetId(String email) throws Exception
    {
        String resetId = String.format("%s%d", (System.currentTimeMillis()+86400000), (long)(Math.random()*100000));
        boolean wasSuccessful = updateResetId(datasource, clientId, userName, email, resetId);
        if ( wasSuccessful )
        {
            this.resetId = resetId;
        }
        return wasSuccessful;
    }
    public boolean updateResetId(String email, String resetId) throws Exception
    {
        boolean wasSuccessful = updateResetId(datasource, clientId, userName, email, resetId);
        if ( wasSuccessful )
        {
            this.resetId = resetId;
        }
        return wasSuccessful;
    }
    public static boolean updateResetId(String datasource, String clientId, String userName, String email, String resetId) throws Exception
    {
        boolean wasSuccessful = false;

        try ( Connection        con  = Connect.open(datasource);
              PreparedStatement  ps  = con.prepareStatement(
                                              "update sit_users "
                                            + "   set reset_id=? "
                                            + " where client_id=? and upper(username)=upper(nvl(?,username)) "
                                            + "   and upper(email)=upper(?)"
                                            );
            )
        {
            ps.setString(1, (resetId == null ? null : String.format("%.30s",resetId)));

            ps.setString(2, clientId);
            ps.setString(3, userName);
            ps.setString(4, email);

            wasSuccessful = ps.executeUpdate() > 0;
        }

        return wasSuccessful;
    }
}
