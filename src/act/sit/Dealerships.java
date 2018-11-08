package act.sit;

import act.util.Connect;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;

public class Dealerships extends ArrayList<Dealership>
{   public Dealerships() 
    {   super();
    }

    public Dealership get(String can)
    {
        if ( can != null )
        {
            for ( Dealership dealership : this )
            {
                if ( can.equals(dealership.can) )
                {
                    return dealership;
                }
            }
        }

        return null;
    }
}
