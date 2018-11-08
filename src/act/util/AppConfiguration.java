package act.util;

import java.io.IOException;
import java.util.Properties;
import javax.servlet.jsp.PageContext;

public class AppConfiguration extends WebConfiguration {
	public AppConfiguration(PageContext pageContext, String string, Properties properties) throws IOException {
		super(pageContext, string, properties);
		SetObject.set(this, this);
	}

	public AppConfiguration(PageContext pageContext, String string) throws IOException {
		super(pageContext, string);
	    SetObject.set(this, this);
	}

	public String 	clientId 		= null;
	public String 	dataSource 		= null;
}
