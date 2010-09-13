package otf.feature.file;

import java.util.List;
import java.util.Vector;

public class Lookup {
	public String name;
	public List<Substitution> substitutions;
	
	public Lookup(String name) {
		this.name = name;
		substitutions = new Vector<Substitution>();
	}
}
