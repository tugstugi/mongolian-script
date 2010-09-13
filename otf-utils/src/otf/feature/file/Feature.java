package otf.feature.file;

import java.util.List;
import java.util.Vector;

public class Feature {
	public String name;
	public List<Lookup> lookups;
	
	public Feature(String name) {
		this.name = name;
		lookups = new Vector<Lookup>();
	}
}
