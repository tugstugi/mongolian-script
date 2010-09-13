package otf.feature.html;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;
import java.util.Vector;

import otf.feature.file.SimpleFeatureFile;

public class HTMLGenerator {
	private SimpleFeatureFile file;
	
	public HTMLGenerator(SimpleFeatureFile file) {
		this.file = file;
	}
	
	public void generate() throws IOException {
		printResource("header");
		generateGlyphTable();
		printResource("footer");
	}
	
	private void generateGlyphTable() {
		String intend = "\t\t";
		System.out.println(intend + "<table class='glyphtable'>");
		for (int i = 0; i < 16*12; i++) {
			int unicodeID = 0x1800 + i;
			if (!(unicodeID == 0x180F || (unicodeID >= 0x181A && unicodeID <= 0x181F) || (unicodeID >= 0x1878 && unicodeID <= 0x187F) || unicodeID >= 0x18AB)) {
				String unicodeName = "uni" + Integer.toHexString(unicodeID).toUpperCase();
				System.out.print(unicodeName + " -> ");
				for (String className : getUsedClasses(unicodeName)) {
					System.out.print(" " + className);
				}
				System.out.println();
			}
		}
		System.out.println(intend + "\t\t</table>");
	}
	
	private List<String> getUsedClasses(String unicodeName) {
		Vector<String> classes = new Vector<String>();
		for (String className : file.classes.keySet()) {
			for (String element : file.classes.get(className)) {
				if (element.startsWith(unicodeName)) {
					classes.add(className);
					break;
				}
			}
		}
		return classes;
	}
	
	private void printResource(String resource) throws IOException {
		BufferedReader reader = new BufferedReader(new InputStreamReader(HTMLGenerator.class.getResourceAsStream(resource)));
		String line = null;
		while ((line = reader.readLine()) != null) {
			System.out.println(line);
		}
		reader.close();
	}

	public static void main(String argv[]) throws IOException {
		if (argv.length == 0) {
			System.out.println("Usage: java otf.feature.html.HTMLGenerator featureFile");
			return;
		}
		SimpleFeatureFile file = new SimpleFeatureFile();
		file.parse(new FileReader(new File(argv[0])));
		HTMLGenerator generator = new HTMLGenerator(file);
		generator.generate();
	}
}
