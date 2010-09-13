package otf.feature.file;

import java.util.List;
import java.util.Vector;

public class Group {
	public boolean shouldReplaced;
	public List<String> elements;
	
	public Group() {
		this.shouldReplaced = false;
		elements = new Vector<String>();
	}
}