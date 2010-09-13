package otf.feature.file;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.Reader;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.StringTokenizer;
import java.util.Vector;

public class SimpleFeatureFile {
	public Map<String, List<String>> classes;
	public List<Feature> features;
	
	public SimpleFeatureFile() {
		classes = new Hashtable<String, List<String>>();
		features = new Vector<Feature>();
	}
	
	private void parseClass(String line) {
		String name = line.substring(line.lastIndexOf('@'), line.lastIndexOf('='));
		Vector<String> elements = new Vector<String>();
		for (String element : line.substring(line.indexOf('[')+1, line.indexOf(']')).split("\\s")) {
			elements.add(element);
		}
		classes.put(name, elements);
	}
	
	private Substitution parseSubstitution(String line) {
		Substitution substitution = new Substitution();
		line = line.substring("sub".length(), line.indexOf(";")).trim();
		if (line.contains("by")) {
			String sub[] = line.split("\\sby\\s");
			if (sub.length == 2) {
				Group group = new Group();
				
				boolean insideAGroup = false;
				StringTokenizer tokenizer = new StringTokenizer(sub[0]);				
				while (tokenizer.hasMoreTokens()) {
					String token = tokenizer.nextToken();
					if (insideAGroup) {
						if (token.contains("]")) {
							insideAGroup = false;
							boolean shouldReplaced = false;
							if (token.endsWith("'")) {
								shouldReplaced = true;
								token = token.substring(0, token.length() - 1);
							}
							group.shouldReplaced = shouldReplaced;
							token = token.substring(0, token.indexOf(']')).trim();
							if (token.length() > 0) {
								group.elements.add(token);
							}
							substitution.groups.add(group);
							group = new Group();
						} else {
							group.elements.add(token);
						}
					} else {
						if (token.contains("[")) {
							insideAGroup = true;
							token = token.substring(1).trim();
							if (token.length() > 0) {
								group.elements.add(token);
							}
						} else {
							boolean shouldReplaced = false;
							if (token.endsWith("'")) {
								shouldReplaced = true;
								token = token.substring(0, token.length() - 1);
							}
							group.shouldReplaced = shouldReplaced;
							group.elements.add(token);
							substitution.groups.add(group);
							group = new Group();
						}
					}
				}
				
				substitution.groups.add(group);
				if (sub[1].contains("[")) {
					sub[1] = sub[1].substring(sub[1].indexOf("[") + 1, sub[1].indexOf("]"));
				}
				for (String element : sub[1].split("\\s")) {
					group.elements.add(element);
				}
			}
		}
		return substitution;
	}
	
	private Lookup parseLookup(String lookupName, BufferedReader reader) throws IOException {
		Lookup lookup = new Lookup(lookupName);
		//System.out.println("    " + lookupName);		
		
		String line = null;		
		while ((line = reader.readLine()) != null && !line.contains("}")) {
			line = line.trim();
			if (line.startsWith("sub") && line.contains(";")) {
				Substitution substitution = parseSubstitution(line);
				lookup.substitutions.add(substitution);
				//System.out.println("        " + substitution.groups.size());
			}
		}
		
		return lookup;
	}
	
	private Feature parseFeature(String featureName, BufferedReader reader) throws IOException {
		Feature feature = new Feature(featureName);
		//System.out.println( featureName);
				
		String line = null;		
		while ((line = reader.readLine()) != null && !line.contains("}")) {
			line = line.trim();
			if (line.startsWith("lookup") && line.length() > "lookup".length() && line.contains("{")) {
				String lookupName = line.substring("lookup".length(), line.indexOf("{")).trim();
				Lookup lookup = parseLookup(lookupName, reader);
				feature.lookups.add(lookup);
			}
		}
		return feature;
	}
	
	public void parse(Reader in) throws IOException {
		BufferedReader reader = new BufferedReader(in);
		String line = null;
		while ((line = reader.readLine()) != null) {
			line = line.trim();
			
			if (line.startsWith("@")) {
				parseClass(line);
			} else if (line.startsWith("feature") && line.length() > "feature".length()) {
				String featureName = null;
				line = line.substring("feature".length() + 1).trim();
				if (line.startsWith("ccmp") || line.startsWith("isol") || line.startsWith("fina") || line.startsWith("medi") || line.startsWith("init") || line.startsWith("rlig") || line.startsWith("calt")) {
					featureName = line.substring(0, "ccmp".length());
				}
				line = line.substring("ccmp".length()).trim();
				if (featureName != null && !line.startsWith(";") && line.contains("{")) {					
					Feature feature = parseFeature(featureName, reader);
					features.add(feature);
				}
			}
		}
		reader.close();
	}
}
