package act.util;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Properties;
import java.util.Arrays;
import java.text.SimpleDateFormat;


/** 1) Specify default configuration directory. This should be relative to the deployemnt root 
 *     (i.e. same directory as "/act_webdev"). 
 *        i.e.: protected static String configurationDirectory = "configuration/"; for "/act_webdev/configuration/"
 *
 *  2) Specify the default configuration file extension, 
 *        i.e.: protected static String configurationExtension = ".cfg";
 *
 *
 *  The methods getConfigurationDirectory() and getConfigurationExtension() must be non-static
 *  otherwise the class containing the executing method, which could be the parent class,
 *  is the value that will be used. When referencing the directory and extension use the
 *  getter() methods to make sure you are getting the correct values, otherwise you may
 *  inadvertently be using the parent classes values intead of the child classes.
 *
 *  Static methods will access static methods/field values of it's class or it's parent
 *  class, not the decendants methods/field values even if declared static.
 *
 *  loadFile(fullFilepath) will load a file from the specified path. 
 *  storeFile(fullFilepath) will save a file to the specified path. 
 *  Both of these methods MUST include the full filename, the set default directory and
 *  extension are not used.
 *
 *  The fields loadError and saveError will hold the most recent exception string if there
 *  was a load or store error.
 *
 *  The method getKeys() returns a String [] with the property keys.
 *
 *  The method updateFieldValues() will set any public fields with the values that are
 *  currently loaded.
 *
 *  Use object.store() to save changes to a previously loaded file.
 *  Use object.store(newName) to create a new configuration file.
 *  
 *  Use object.removeDefaults() to remove the default properties.
 *  Use object.setDefaults() to set or change the default properties.
 *  Use object.getDefaults() to get the currently set default properties.
 *
 *  getFilepath() returns the fully qualified file path of the loaded configuration file.
 */
public class WebConfiguration extends Properties {

    /** The configuration properties directory, relative to the deployment directory */
    protected final static String configurationDirectory = "_configuration/";

    /** Returns the configuration properties directory, relative to the same directory as classes */
    public    String getConfigurationDirectory() { return configurationDirectory; }

    /** The configuration properties file extension */
    protected static String configurationExtension = ".cfg";

    /** Returns the configuration properties file extension */
    public    String getConfigurationExtension() { return configurationExtension; }


    public WebConfiguration(javax.servlet.jsp.PageContext pageContext, String filename) throws IOException {
        load(pageContext, filename);
    }
    public WebConfiguration(javax.servlet.jsp.PageContext pageContext, String filename,
                         Properties defaults) throws IOException {
        super(defaults);
        load(pageContext, filename);
    }

    /**Sets the properties root directory, offset from the deployment root
     */
    protected void setRootDirectory(javax.servlet.jsp.PageContext pageContext) throws IOException {
        try {
            javax.servlet.ServletContext application = pageContext.getServletContext();
            baseDirectory = application.getRealPath("") + "/";
        } catch (Exception exception) {
            throw new IOException(exception.getMessage());
        }
    }

    /**Returns the properties root directory, offset from the base /classes/
     * directory location.
     * @returns properties root directory
     */
    public String getRootDirectory() throws IOException {
        return this.getBaseDirectory() + getConfigurationDirectory();
    }

    /**The filename of the properties loaded by name or set through the
     * setFilename() method.
     */
    protected String propertyFilename = null;

    /**Returns the filename of the properties loaded by name or set through the
     * setFilename() method.
     * @returns current propery filename
     */
    public String getFilename() { return propertyFilename; }


    /**Sets the current property filename for use by the store() method.
     * @params filename the filename to use when storing the properties file.
     * @throws IOException if no filename is specified
     */
    public void setFilename(String filename) throws IOException { 
        if ( propertyFilename == null || propertyFilename.length() == 0 )
            throw new IOException("Unable to set filename: no filename specified");
        propertyFilename = filename; 
    }

    /**Reads a property list (key and element pairs) from the specified filename.
     * The file location is defined by the system.
     * @params name The name of the property file.
     * @throws IOException if an error occurs loading the property file
     */
    public void load(javax.servlet.jsp.PageContext pageContext, String name) throws IOException {
        setRootDirectory(pageContext);
        propertyFilename = name;
        loadFile(getRootDirectory() + (name.indexOf(".") >= 0 ? name : name + getConfigurationExtension()));
    }

    /**Writes this property list (key and element pairs) in this Properties 
     * table in a format suitable for loading into a Properties table using 
     * the load(InputStream) method.
     * @throws IOException if an error occurs saving the property file
     */
    public void store() throws IOException {
        if ( propertyFilename == null || propertyFilename.length() == 0 )
            throw new IOException("Unable to store file: no filename defined");
        storeFile(getRootDirectory() + (propertyFilename.indexOf(".") >= 0 ? propertyFilename : propertyFilename + getConfigurationExtension()));
    }

    /**Writes this property list (key and element pairs) in this Properties 
     * table in a format suitable for loading into a Properties table using 
     * the load(InputStream) method.
     * The property file is specified by the name parameter.
     * @params name The name of the property file.
     * @throws IOException if an error occurs saving the property file
     */
    public void store(String name) throws IOException {
        propertyFilename = name;
        storeFile(getRootDirectory() + (name.indexOf(".") >= 0 ? name : name + getConfigurationExtension()));
    }

    /**Reads a property list (key and element pairs) from the input byte stream.
     * System fields are updated after stream is loaded.
     * @params inStream the input stream
     * @throws IOException if an error occurs loading the data from the stream
     */
    public void load(InputStream inStream) throws IOException {
        super.load(inStream);
        updateFieldValues();
    }

    /**Reads a property list (key and element pairs) from the input character stream in a simple line-oriented format.
     * System fields are updated after stream is loaded.
     * @params reader the reader stream
     * @throws IOException if an error occurs loading the data from the reader
     */
    public void load(Reader reader) throws IOException {
        super.load(reader);
        updateFieldValues();
    }

    /**Loads all of the properties represented by the XML document on the specified input stream into this properties table.
     * System fields are updated after stream is loaded.
     * @params inStream the input stream
     * @throws IOException if an error occurs loading the data from the stream
     */
    public void loadFromXML(InputStream inStream) throws IOException {
        super.loadFromXML(inStream);
        updateFieldValues();
    }


    public void updateFieldValues() { return; }


    /**Holds the root directory location where the /classes/ directory is */
    protected String baseDirectory = null;

    /**Returns the file system root directory of where the /classes/ directory is.
     * @returns URL path to the base directory, same as where /classes/ is located.
     */
    public String getBaseDirectory() throws IOException { 
        if ( baseDirectory == null ) throw new IOException("Base directory is undefined");
        return baseDirectory; 
    }


    /** Verifies that the file system directory path exists.
     *  If the specified directory doesn't exist it is created. If
     *  the path is a directory it must end with a trailing slash.
     *  If the path doesn't have a trailing slash it is assumed to be
     *  a file name and only the directory portion is verified.
     *  @param path file system directory path to verify
     */
    public void verifyFilePath(String path) {
        if ( path == null ) return;

        // Normalize our path string (DOS vs Unix) and make sure we have
        // only the directory portion.
        path = path.replaceAll("\\\\","/"); // Convert to Unix standard

        // If the path is a filename we'll extract the directory portion
        if ( path.indexOf("/") > 0 && ! path.endsWith("/") ) {
            path = path.substring(0,path.lastIndexOf("/"));
        }

        // Verify that the directory exists, otherwise create it
        File directory = new File(path);
        if ( ! directory.exists() ) directory.mkdirs();
    }


    /**Changes the default properties used by this object.
     * Overwrites the default properites specified when creating the object
     * with new defaults. No current properties are affected or changed, only
     * the default property values returned if a property value is not defined.
     * @params newDefaults the replacement default properties
     */
    public void setDefaults(Properties newDefaults) { this.defaults = newDefaults; }

    /**Removes the default properties used by this object.
     * Removes the default properites so any property not defined within the
     * current object will return null. Has the same effect as creating the
     * object with no default properties defined. No current properties are 
     * affected or changed, only the default property values returned if a 
     * property value is not defined.
     */
    public void removeDefaults() { this.defaults = null; }

    /**Returns a copy of the default properties used by this object.
     * The currently defined default properties is cloned and returned. If
     * no default properties are defined then null is returned.
     * @returns A cloned copy of the default properties, or null if no
     * default poperties were defined.
     */
    public Properties getDefaults() {
        return (Properties)(this.defaults == null ? null : this.defaults.clone()); 
    }


    /**The full filepath of the file last loaded by name */
    protected String filepath = null;

    /**Returns the full filepath of the file last loaded by name.
     * If properties have been loaded by IOStream or some other method
     * this value will not be updated.
     * @returns Full filesystem filepath
     */
    public String getFilepath() { return filepath; }

    /**Loads the specified property file.
     * @param fullFilepath The full file pathname to the file to load
     * @throws IOException If unable to load property file
     */
    protected void loadFile(String fullFilepath) throws IOException {
        java.io.InputStream in = null;

        try {
            loadError = null;

            if ( fullFilepath != null && fullFilepath.startsWith("file:/") )
                fullFilepath = fullFilepath.substring(5);

            if ( fullFilepath == null || fullFilepath.length() == 0 )
                throw new IOException("Unable to load file: No name specified");

            File fileToLoad = new File(fullFilepath);
            if ( ! fileToLoad.exists() )
                throw new IOException("Unable to load file: File does not exist");

            load((in = (new FileInputStream(fileToLoad))));
            filepath = fileToLoad.getAbsolutePath();
        } catch (IOException e) {
            loadError = "Failed to load file (" + fullFilepath + ")\n" + e.toString();
            throw e;
        } finally {
            if ( in != null ) { try { in.close(); } catch (Exception e) {} in = null; }
        }

        return;
    }



    /**Saves the property file with the specified filename.
     * @param fullFilepath The full file pathname to the file to save
     * @throws IOException If unable to save property file
     */
    protected void storeFile(String fullFilepath) throws IOException {
        java.io.OutputStream out = null;

        try {
            saveError = null;

            if ( fullFilepath != null && fullFilepath.startsWith("file:/") )
                fullFilepath = fullFilepath.substring(5);

            if ( fullFilepath == null || fullFilepath.length() == 0 )
                throw new IOException("Unable to store file: No name specified");

            if ( baseDirectory == null || ! fullFilepath.startsWith(baseDirectory) )
                throw new IOException("Unable to store file: Base directory is undefined");

            File fileToStore = new File(fullFilepath);

            super.store((out = (new FileOutputStream(fileToStore))),null);
        } catch (IOException e) {
            saveError = "Failed to save file (" + fullFilepath + ")\n" + e.toString();
            throw e;
        } finally {
            if ( out != null ) { try { out.close(); } catch (Exception e) {} out = null; }
        }

        return;
    }


    protected String loadError = null;
    public String getLoadError() {
        return loadError;
    }
    protected String saveError = null;
    public String getSaveError() {
        return saveError;
    }



    /**Returns a property value as an integer value, defaults to 0 if value isn't an integer value 
     * @param property property to return the value of
     * @returns property value or "" if value is null
     */
    public String getString(String property) {
        return getString(property, "");
    }

    /** Returns a property value as an integer value, returns default value if value isn't an integer value
     * @param property property to return the value of
     * @param def value to return if property value is null
     * @returns property value or default value if value is null
     */
    public String getString(String property, String def) {
        String value = getProperty(property);
        return (value == null ? def : value);
    }


    /** Returns a property value as an integer value, defaults to 0 if value isn't an integer value
     * @param property property to return the value of
     * @returns property value or 0 if value is null
     */
    public int getInt(String property) {
        return getInt(property, 0);
    }

    /** Returns a property value as an integer value, returns default value if value isn't an integer value
     * @param property property to return the value of
     * @param def value to return if property value is null
     * @returns property value or default value if value is null
     */
    public int getInt(String property, int def) {
        try {
            return Integer.parseInt(this.getProperty(property));
        } catch (Exception e) {
        }
        return def;
    }

    /** Returns a property value as a long value, defaults to 0 if value isn't a long value
     * @param property property to return the value of
     * @returns property value or 0 if value is null
     */
    public long getLong(String property) {
        return getLong(property, 0l);
    }

    /** Returns a property value as a long value, returns default value if value isn't a long value
     * @param property property to return the value of
     * @param def value to return if property value is null
     * @returns property value or default value if value is null
     */
    public long getLong(String property, long def) {
        try {
            return Long.parseLong(this.getProperty(property));
        } catch (Exception e) {
        }
        return def;
    }

    /** Returns a property value as a double value, defaults to 0.0 if value isn't a double value
     * @param property property to return the value of
     * @returns property value or 0.0 if value is null
     */
    public double getDouble(String property) {
        return getDouble(property, 0.0);
    }

    /** Returns a property value as a double value, returns default value if value isn't a double value
     * @param property property to return the value of
     * @param def value to return if property value is null
     * @returns property value or default value if value is null
     */
    public double getDouble(String property, double def) {
        try {
            return Double.parseDouble(this.getProperty(property));
        } catch (Exception e) {
        }
        return def;
    }

    /** Returns a property value as a boolean true/false value, calls isTrue(property) method
     * @param property property to return the boolean value of
     * @returns true if property value is "TRUE" or "Y", false otherwise
     */
    public boolean getBoolean(String property) {
        return isTrue(property);
    }

    /** Returns a property value as a boolean true/false value, value must be "true" or "Y" to return true
     * @param property property to return the boolean value of
     * @returns true if property value is "TRUE" or "Y", false otherwise
     */
    public boolean isTrue(String property) {
        return "true".equalsIgnoreCase(this.getProperty(property)) || "Y".equalsIgnoreCase(this.getProperty(property));
    }

    /** Returns a property value as a boolean true/false value, returns true if isTrue() returns false
    * @param property property to determine whether the value evaluates to true or not
    * @returns true if property value is not "TRUE" and is not "Y", false otherwise
    */
    public boolean isFalse(String property) {
        return ! isTrue(this.getProperty(property));
    }

    /** Returns whether a value is defined or not
     *  The value is determined to be defined if it is not null and has a length greater than 0.
     *  @param val value to check
     *  @returns true if value is defined, false otherwise
     */
    public boolean notDefined(String val) {
        return val == null || val.length() == 0;
    }

    
    /** Returns property value of the first property if value is not null, otherwise returns the value of property2 
     *  @param property1 property value to return if value is not null
     *  @param property2 property value to return if property1 value is null
     *  @returns value of property1 if the value is not null, otherwise the value of property2 is returned
     */
    public String getNvl(String property1, String property2) {
        return (this.getProperty(property1) == null ? this.getProperty(property2) : this.getProperty(property1));
    }


    /** Returns a String [] containing the defined property keys
     */
    public String[] getKeys() {
        String[] keys = (String[])this.keySet().toArray(new String[this.size()]);
        Arrays.sort(keys);
        return keys;
    }


    // Need to add date getter methods


    protected static SimpleDateFormat externalDatetimeFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm");
    public    static String datetimeToExternal(long datetime) {
        return datetimeToExternal(new java.util.Date(datetime));
    }
    public    static String datetimeToExternal(java.util.Date datetime) {
        if ( datetime == null ) return "";
        return externalDatetimeFormat.format(datetime);
    }


    /** Returns the specified date/time string to a java datetime long value
     *
     *  See getDatetime() for supported formats.
     *
     *  @param datetime date/time String value to parse
     *  @returns long value corresponding to the Date time value, null if parameter is null.
     *  @throws Exception if there is a parse error or the datetime format was not identified
     */
    public  long decodeDatetime(String datetime) throws Exception {
        return getDatetime(datetime).getTime();
    }


    /** Returns the specified date/time string to a java Date object
     *
     *  Supported datetime formats are:
     *
     *      y-M-d h:m a           2016-05-01 3:03 PM
     *      y-M-d H:m             2016-05-01 15:03
     *      y-M-d h:m:s a         2016-05-01 3:03:00 PM
     *      y-M-d H:m:s           2016-05-01 15:03:00
     *
     *      M/d/y h:m a           05/01/2016 3:03 PM
     *      M/d/y H:m             05/01/2016 15:03
     *      M/d/y h:m:s a         05/01/2016 3:03:00 PM
     *      M/d/y H:m:s           05/01/2016 15:03:00
     *
     *      y-MMM-d h:m a         2016-May-01 3:03 PM
     *      y-MMM-d H:m           2016-May-01 15:03
     *      y-MMM-d h:m:s a       2016-May-01 3:03:00 PM
     *      y-MMM-d H:m:s         2016-May-01 15:03:00
     *
     *      MMM d, y h:m a        May 01, 2016 3:03 PM
     *      MMM d, y H:m          May 01, 2016 15:03
     *      MMM d, y h:m:s a      May 01, 2016 3:03:00 PM
     *      MMM d, y H:m:s        May 01, 2016 15:03:00
     *
     *      y-M-d                 2016-05-01
     *      M/d/y                 05/01/2016
     *      y-MMM-d               2016-May-01
     *      MMM d, y              May 01, 2016
     *      E MMM d H:m:s z y     Sun May 01 15:03:28 CDT 2016
     *
     *  @param datetime date/time String value to parse
     *  @returns Date object set to the corresponding date/time of the datetime parameter, null if parameter is null.
     *  @throws Exception if there is a parse error or the datetime format was not identified
     */
    public    static java.util.Date getDatetime(String datetime) throws Exception {
        if ( datetime == null ) return null;

        // If this is already a numerical date/time value decode and return it
        if ( datetime.matches("[0-9]{1,}") ) return new java.util.Date(Long.parseLong(datetime));

        // Loop through our defined formats and convert if possible
        for ( int formatIdx=0; formatIdx < datetimeFormats.length; formatIdx++ ) {
            if ( datetime.matches(datetimeFormats[formatIdx][1]) )
                return (new SimpleDateFormat(datetimeFormats[formatIdx][0])).parse(datetime);
        }

        throw new Exception("Invalid format"); //return null;
    }

    /** Date/time conversion formats and corresponding regex match patterns */
    protected static String [][] datetimeFormats = new String [][] {
            // Match "2016-10-01 4:21 PM" format
            { "y-M-d h:m a", "(20){0,1}[12][0-9]-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "2016-10-01 16:21" format
            { "y-M-d H:m", "(20){0,1}[12][0-9]-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}" },

            // Match "2016-10-01 4:21:00 PM" format
            { "y-M-d h:m:s a", "(20){0,1}[12][0-9]-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "2016-10-01 16:21:00" format
            { "y-M-d H:m:s", "(20){0,1}[12][0-9]-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}" },

            // Match "10-01-2016" format
            { "M-d-y", "[01]{1}[0-9]{1}-[0123]{1}[0-9]{1}-(20){1}[12][0-9]" },

            // Match "10012016" format
            { "M-d-y", "[01]{1}[0-9]{1}[0123]{1}[0-9]{1}(20){1}[12][0-9]" },

            // Match "2016-10-01" format
            { "y-M-d", "(20){1}[12][0-9]-[0-9]{1,2}-[0-9]{1,2}" },


            // Match "10/1/2016 4:21 PM" format
            { "M/d/y h:m a", "[0-9]{1,2}/[0-9]{1,2}/(20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "10/1/2016 16:21" format
            { "M/d/y H:m", "[0-9]{1,2}/[0-9]{1,2}/(20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2}" },

            // Match "10/1/2016 4:21:00 PM" format
            { "M/d/y h:m:s a", "[0-9]{1,2}/[0-9]{1,2}/(20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "10/1/2016 16:21:00" format
            { "M/d/y H:m:s", "[0-9]{1,2}/[0-9]{1,2}/(20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}" },

            // Match "10/1/2016" format
            { "M/d/y", "[0-9]{1,2}/[0-9]{1,2}/(20){0,1}[12][0-9]" },


            // Match "2016-OCT-01 4:21 PM" format
            { "y-MMM-d h:m a", "(20){0,1}[12][0-9]-[A-Za-z]{3,}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "2016-OCT-01 16:21" format
            { "y-MMM-d H:m", "(20){0,1}[12][0-9]-[A-Za-z]{3,}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}" },

            // Match "2016-OCT-01 4:21:00 PM" format
            { "y-MMM-d h:m:s a", "(20){0,1}[12][0-9]-[A-Za-z]{3,}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "2016-OCT-01 16:21:00" format
            { "y-MMM-d H:m:s", "(20){0,1}[12][0-9]-[A-Za-z]{3,}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}" },

            // Match "2016-OCT-01" format
            { "y-MMM-d", "(20){0,1}[12][0-9]-[A-Za-z]{3,}-[0-9]{1,2}" },


            // Match "OCT 01, 2016 4:21 PM" format
            { "MMM d, y h:m a", "[A-Za-z]{3,} [0-9]{1,2}, (20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "OCT 01, 2016 16:21" format
            { "MMM d, y H:m", "[A-Za-z]{3,} [0-9]{1,2}, (20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2}" },

            // Match "OCT 01, 2016 4:21:00 PM" format
            { "MMM d, y h:m:s a", "[A-Za-z]{3,} [0-9]{1,2}, (20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [APap][mM]" },
            // Match "OCT 01, 2016 16:21:00" format
            { "MMM d, y H:m:s", "[A-Za-z]{3,} [0-9]{1,2}, (20){0,1}[12][0-9] [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}" },

            // Match "OCT 01, 2016" format
            { "MMM d, y", "[A-Za-z]{3,} [0-9]{1,2}, (20){0,1}[12][0-9]" },


            // Match "Sun Oct 01 16:21:00 CDT 2016" format - same format as Date.toString()
            { "E MMM d H:m:s z y", "[A-Za-z]{3,} [A-Za-z]{3,} [0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [A-Z]{3} (20){0,1}[12][0-9]" }

            };

}
