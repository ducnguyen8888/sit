package act.util;

import java.text.*;
import java.util.*;
import java.io.IOException;
import java.lang.reflect.*;


public class SetObject {
    public SetObject() {}


    public static String nvl(String val, String def) {
        return (val == null || val.trim().length() == 0 ? def : val);
    }


    /**
     * Sets the public fields of the specified object with the values
     * from the properties object. 
     * The value is identified as the property value of the key with
     * the same name as the field. Names are case-sensitive. 
     *
     * @param object the Object to set the fields of
     * @param properties the Properties object that holds the values
     **/
	public static void set(Object object, Properties properties) {
		if ( object == null || properties == null ) return;

        for ( Field field : object.getClass().getDeclaredFields() ) {
            if ( ! okToSetValue(field) ) continue;

            String fieldName  = field.getName();

            // Properties must contain an entry for the field
            if ( ! properties.containsKey(fieldName) ) continue;
            String fieldValue = properties.getProperty(fieldName);

            Class  fieldClassType  = field.getType();

            try {
                if ( fieldClassType.equals(Integer.TYPE) ) {
                    field.setInt(object,Integer.parseInt(fieldValue));
                } else if ( fieldClassType.equals(String.class) ) {
                    field.set(object, fieldValue);
                } else if ( fieldClassType.equals(Long.TYPE) ) {
                    field.setLong(object,Long.parseLong(fieldValue));
                } else if ( fieldClassType.equals(Double.TYPE) ) {
                    field.setDouble(object,Double.parseDouble(fieldValue));
                } else if ( fieldClassType.equals(Boolean.TYPE) ) {
                    field.setBoolean(object,Boolean.parseBoolean(fieldValue));
                } else if ( fieldClassType.isArray() ) {
                    String separator = nvl(properties.getProperty(fieldName+".$separator"),",");
                    String [] values = fieldValue.split(separator);
                    for ( int i=0; i < values.length; i++ )
                        values[i] = values[i].trim();

                    field.set(object, convertStringArray(fieldClassType.getComponentType(),values));
                } else {
                    // If there isn't a class for this object or there isn't a String
                    // constructor an exception will be thrown and any default value
                    // will remain unchanged.
                    String classTypeName = nvl(properties.getProperty(fieldName+".$class"),fieldClassType.getName());
                    Class classInstance = Class.forName(classTypeName);

                    Object newObject = null;
                    if ( fieldValue.length() == 0 ) {
                        newObject = classInstance.newInstance();
                    } else {
                        Constructor constructor = classInstance.getConstructor(String.class);
                        newObject = constructor.newInstance(fieldValue);
                    }
                    field.set(object,newObject);

                    // Check to see if there are fields to set for this class field
                    Properties altProperties = new Properties();
                    for ( String key : (String [])properties.keySet().toArray(new String[0]) ) {
                        if ( ! key.startsWith(fieldName+".") ) continue;

                        // Extract the sub-key information
                        String keyName  = key.replaceAll("([^\\.]{1,})\\.(.*)","$1");
                        if ( keyName.equals(key) ) continue;

                        String keyValue = key.replaceAll("([^\\.]{1,})\\.(.*)","$2");
                        if ( keyValue.startsWith("$") ) continue;

                        altProperties.setProperty(keyValue,properties.getProperty(key));
                    }
                    if ( altProperties.size() > 0 ) {
                        set(newObject,altProperties);
                    }
                }
            } catch (Exception ignore) {
                //System.out.println("Exception: " + ignore.getCause());
                ;
            }
        }

		return;
	}

    /** Identified the field modifiers of fields that should not be set in setFieldFromString(..) */
    protected static int restrictedModifiers = (Modifier.ABSTRACT|Modifier.STATIC|Modifier.FINAL);

    /**
     * Identifies whether the field should not be assigned to.
     * Returns true if the field is not restricted (abstact/public/static) or
     * is a run-time type of field (syntheic)
     * @param field Field to check assignability
     * @return true if it won't cause problems to assign the field value
     */
    public static boolean okToSetValue(Field field) {
        boolean dontAssignField = (field == null)
                            || field.isSynthetic() 
                            || 0 < (field.getModifiers() & restrictedModifiers);
        return ! dontAssignField;
    }


    /**
     * Converts a String array to an array of the specified base type.
     * If the target type is a class then the class(String) constructor
     * is used to instantiate the object. If the specified target class
     * type does not have a (String) constructor then the class will not
     * be instantiated.
     * @param newClassType the target class type to covert the source array to
     * @param arrayValues the source values to convert
     * @throws Exception if a conversion exception occurs
     **/
    public static Object convertStringArray(Class newClassType, String [] arrayValues) throws Exception {
        Object newArray = null;

        try {
            int arrayLength = (arrayValues == null ? 0 : arrayValues.length);

            if ( newClassType.equals(Integer.TYPE) ) {
                if ( arrayLength == 1 && (arrayValues[0] == null || arrayValues[0].trim().length() == 0) )
                    arrayLength = 0;

                newArray = Array.newInstance(Integer.TYPE, arrayLength);
                for ( int i=0; i < arrayLength; i++ ) {
                    int intValue = 0;
                    try {
                        intValue = Integer.parseInt(arrayValues[i].trim());
                    } catch (Exception ignore) {
                        ;
                    }
                    Array.set(newArray,i,intValue);
                }
            } else if ( newClassType.equals(String.class) ) {
                newArray = (String []) Array.newInstance(newClassType, arrayLength);
                for ( int i=0; i < arrayLength; i++ ) {
                    Array.set(newArray,i,arrayValues[i].trim());
                }
            } else if ( newClassType.equals(Long.TYPE) ) {
                if ( arrayLength == 1 && (arrayValues[0] == null || arrayValues[0].trim().length() == 0) )
                    arrayLength = 0;

                newArray = (long []) Array.newInstance(Long.TYPE, arrayLength);
                for ( int i=0; i < arrayLength; i++ ) {
                    long longValue = 0;
                    try {
                        longValue = Long.parseLong(arrayValues[i].trim());
                    } catch (Exception ignore) {
                        ;
                    }
                    Array.set(newArray,i,longValue);
                }
            } else if ( newClassType.equals(Double.TYPE) ) {
                if ( arrayLength == 1 && (arrayValues[0] == null || arrayValues[0].trim().length() == 0) )
                    arrayLength = 0;

                newArray = (double []) Array.newInstance(Double.TYPE, arrayLength);
                for ( int i=0; i < arrayLength; i++ ) {
                    double doubleValue = 0;
                    try {
                        doubleValue = Double.parseDouble(arrayValues[i].trim());
                    } catch (Exception ignore) {
                        ;
                    }
                    Array.set(newArray,i,doubleValue);
                }
            } else if ( newClassType.equals(Boolean.TYPE) ) {
                newArray = (boolean []) Array.newInstance(newClassType, arrayLength);
                for ( int i=0; i < arrayLength; i++ ) {
                    Array.set(newArray,i,Boolean.parseBoolean(arrayValues[i].trim()));
                }
            } else {
                Class classInstance = Class.forName(newClassType.getName());
                Constructor constructor = classInstance.getConstructor(String.class);
                newArray = (Object []) Array.newInstance(newClassType, arrayLength);
                for ( int i=0; i < arrayLength; i++ ) {
                    Array.set(newArray,i,constructor.newInstance(arrayValues[i]));
                }
            }
        } catch (Exception e) {
            throw e;
        }

        return newArray;
    }




    /**
     * Lists the object fields and values of the object.
     * @param obj the object to list the public fields of
     * @return A string output, similar to toString(), of the
     *         object fields/values
     **/
	public static String listFields(Object obj) {
		StringBuffer buffer = new StringBuffer();
		if ( obj == null ) return ("");

		//Field [] fields = obj.getClass().getFields();
		Field [] fields = obj.getClass().getDeclaredFields();
        //Field [] fields = getAllFields(obj.getClass());

		for ( int i=0; i < fields.length; i++ ) {
			//if ( fields[i].getModifiers() != Modifier.PUBLIC ) continue;

			Class  classType  = fields[i].getType();

			// We won't address non-string class objects
			//if ( classType.toString().startsWith("class") && ! classType.getName().equals("java.lang.String") ) continue;

			String fieldName  = fields[i].getName();
			String fieldValue = "";

			try {
				if ( fields[i].get(obj) != null ) {
					if ( classType.equals(java.lang.Integer.TYPE) ) {
						fieldValue = ""+fields[i].getInt(obj);
					} else if ( classType.equals(java.lang.Boolean.TYPE) ) {
						fieldValue = ""+fields[i].getBoolean(obj);
					} else if ( classType.equals(java.lang.Long.TYPE) ) {
						fieldValue = ""+fields[i].getLong(obj);
					} else if ( classType.equals(java.lang.Double.TYPE) ) {
						fieldValue = ""+fields[i].getDouble(obj);
					//} else if ( classType.getName().equals("java.lang.String") ) {
					//	fieldValue = (String)fields[i].get(obj);
					} else if ( classType.isArray() ) {
                        fieldValue = "is-an-Array-of-some-type: " + classType.getComponentType();
                        fieldValue = "(Size: " + Array.getLength(fields[i].get(obj)) + ")\n";
                        for ( int j=0; j < Array.getLength(fields[i].get(obj)); j++ ) {
                            fieldValue += "\t\tValue " + j + ": " + Array.get(fields[i].get(obj),j).toString()+"\n";
                        }
					} else {
                        fieldValue = fields[i].get(obj).toString();
						//continue;
					}
				}
			} catch (Exception e) {
                ;
			}

            buffer.append("Type: " + classType + "\n");
			buffer.append( fieldName + "=" + fieldValue + "\n\n");
		}

		return buffer.toString();
	}

}