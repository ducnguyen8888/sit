package act.sit;


public class Recents {

	java.util.ArrayList al =  new java.util.ArrayList();
	public final int MAXSIZE = 5;
	
	public Recents(){}

	public void   clear(){ al.clear() ;}
	
	public void add(String can, String name){
        for (int i = 0; i < al.size(); i++){
           if( can.equals(((ListItem)al.get(i)).can)){
               al.remove(i);// removes repeat
           }
       }		
		al.add(new ListItem(can, name));
		if(al.size() > MAXSIZE)
		   al.remove(0);
	}//add
	
	public String toString (){
		StringBuffer sb = new StringBuffer();
		
	    sb.append("<div id=\"sideBar\"><table id=\"recentsTable\" style=\"width:100%\">\r\n");
	     
        for (int i = al.size()-1; i > -1; i--){
            sb.append("<tr><td class=\"recent\"><a href=\"#\">" + ((ListItem)al.get(i)).can + "</a>"); 
            sb.append("<div id=\"sidebarRecent\">" + ((ListItem)al.get(i)).name + "</div></td></tr>\r\n");
         }   
        sb.append("</table></div>");
		return sb.toString();
	}

	static class ListItem{
        String can = "";
        String name = "";
        
        ListItem(){}
        ListItem(String can, String name){
            this.can = can;
            this.name = name;
        }
    }// class listItem	
}// class Recents
