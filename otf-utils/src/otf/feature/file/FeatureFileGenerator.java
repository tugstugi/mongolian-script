package otf.feature.file;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.List;
import java.util.Vector;

public class FeatureFileGenerator {
	private SimpleFeatureFile file;
	
	public FeatureFileGenerator(SimpleFeatureFile file) {
		this.file = file;
	}
	
	public void generate() {
		strip();
		Vector<String> validLookups = new Vector<String>();
		for (String lookup : "isol3 isol4 fina5 fina6 medi7 medi8 init9 init10".split("\\s")){
			validLookups.add(lookup);
		}
		for (String lookup : "rlig11 rlig13 rlig14 rlig18 rlig76".split("\\s")){
			validLookups.add(lookup);
		}
		for (String lookup : "calt19 calt20 calt21 calt22 calt23 calt24 calt25 calt26 calt44 calt48 calt49 calt50 calt51 calt52 calt53 calt57 calt58 calt59 calt60 calt62 calt63 calt64 calt65 calt66 calt71 calt73 calt74 calt75 calt77 calt78 calt79 calt81 calt82 calt83 calt84 calt85 calt87 calt88".split("\\s")){
			validLookups.add(lookup);
		}
		
		generateClasses();
		
		for (Feature feature : file.features) {
			if (!feature.name.equals("ccmp") && !feature.name.equals("vert")) {
				generateFeature(feature, validLookups);
			}
		}
	}
	
	private void generateClasses() {
		for (String className : file.classes.keySet()) {
			List<String> glyphs = file.classes.get(className);
			if (glyphs.size() > 0) {
				System.out.print(className + "=[");
				for (String glyphName : glyphs) {
					System.out.print(glyphName + " ");
				}
				System.out.println("];");
			}
		}
	}
	
	private void generateFeature(Feature feature, List<String> validLookups) {
		System.out.println("\n\n\n\n");
		System.out.println("feature " + feature.name + " {");
		System.out.println("\tscript mong;");
		
		Vector<String> acceptedLookups = new Vector<String>();
		for (Lookup lookup : feature.lookups) {
			if (validLookups.contains(lookup.name) && acceptLookup(lookup)) {
				acceptedLookups.add(lookup.name);
				System.out.println("\tlookup " + lookup.name + " {");
				for (Substitution sub : lookup.substitutions) {
					if (acceptSub(sub)) {
						generateSub(sub);
					}
				}
				System.out.println("\t} " + lookup.name + " ;");
			}
		}
		
		System.out.println("\tlanguage MCH exclude_dflt;");
		System.out.println("\tlanguage MNG exclude_dflt;");
		for (String lookupName : acceptedLookups) {
			System.out.println("\tlookup " + lookupName + ";");
		}
		System.out.println("\tlanguage SIB exclude_dflt;");
		System.out.println("\tlanguage TOD exclude_dflt;");
		System.out.println("} " + feature.name + " ;");
	}
	
	private void generateSub(Substitution sub) {
		System.out.print("\t\tsub ");
		boolean allReplaceable = isAllReplaceable(sub);
		for (int i = 0; i < sub.groups.size() - 1; i++) {
			Group group = sub.groups.get(i);
			boolean replaceable = group.shouldReplaced;
			if (allReplaceable)
				replaceable = false;
			generateGroup(group, replaceable);
		}
		System.out.print(" by ");
		generateGroup(sub.groups.get(sub.groups.size()-1), false);
		System.out.println(" ;");
	}
	
	private boolean isAllReplaceable(Substitution sub) {
		for (int i = 0; i < sub.groups.size() -1; i++) {
			if (!sub.groups.get(i).shouldReplaced) {
				return false;
			}
		}
		return true;
	}
	
	private void generateGroup(Group group, boolean replaceable) {
		if (group.elements.size() > 1) {
			System.out.print("[");
			for (String glyphName : group.elements) {
				System.out.print(glyphName + " ");
			}
			System.out.print("]");			
		} else {
			System.out.print(group.elements.get(0));
		}
		
		if (replaceable)
			System.out.print("'");
		
		System.out.print(" ");
	}
	
	private void strip() {
		for (List<String> glyphs : file.classes.values()) {
			strip(glyphs);
		}
		for (Feature feature : file.features) {
			for (Lookup lookup : feature.lookups) {
				for (Substitution sub : lookup.substitutions) {
					for (Group group : sub.groups) {
						strip(group.elements);
					}
				}
			}
		}
	}
	
	private void strip(List<String> glyphs) {
		Vector<String> tobeRemoved = new Vector<String>();
		for (String glyphName : glyphs) {
			if (!accept(glyphName)) {
				tobeRemoved.add(glyphName);
			}
		}
		glyphs.removeAll(tobeRemoved);
	}
	
	private boolean accept(String glyphName) {
		if (!glyphName.startsWith("uni"))
			return false;
		for (int i = 0x1800; i <= 0x1842; i++) {
			String hex = Integer.toHexString(i).toUpperCase();
			if (glyphName.contains(hex))
				return true;
		}
		return false;
	}
	
	private boolean acceptLookup(Lookup lookup) {
		for (Substitution sub: lookup.substitutions) {
			if (acceptSub(sub))
				return true;
		}
		return false;
	}
	
	private boolean acceptSub(Substitution sub) {
		for (Group group : sub.groups) {
			if (group.elements.size() == 0)
				return false;
		}
		return true;
	}
	
	public static void main(String argv[]) throws IOException {
		if (argv.length == 0) {
			System.out.println("Usage: java otf.feature.file.FeatureFileGenerator featureFile");
			return;
		}
		SimpleFeatureFile file = new SimpleFeatureFile();
		file.parse(new FileReader(new File(argv[0])));
		FeatureFileGenerator generator = new FeatureFileGenerator(file);
		generator.generate();
	}
}
