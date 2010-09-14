package otf.feature.html;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.StringWriter;
import java.io.Writer;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import otf.feature.file.Feature;
import otf.feature.file.Group;
import otf.feature.file.Lookup;
import otf.feature.file.SimpleFeatureFile;
import otf.feature.file.Substitution;

public class HTMLGenerator {
	private SimpleFeatureFile file;
	private Set<String> allGlyphSet;
	private Set<String> allLigatureSet;
	
	public HTMLGenerator(SimpleFeatureFile file) {
		this.file = file;
		
		Vector<String> glyphs = new Vector<String>();
		for (List<String> elements : file.classes.values()) {
			glyphs.addAll(elements);
		}
		for (Feature feature : file.features) {
			for (Lookup lookup : feature.lookups) {
				for (Substitution substitution : lookup.substitutions) {
					for (Group group : substitution.groups) {
						for (String element : group.elements) {
							if (!element.startsWith("@")) {
								glyphs.add(element);
							}
						}
					}
				}
			}
		}
		Collections.sort(glyphs);
		allGlyphSet = new HashSet<String>();
		allGlyphSet.addAll(glyphs);
		allLigatureSet = new HashSet<String>();
		for (String glyph : allGlyphSet) {
			if (glyph.contains(".") && glyph.substring(0, glyph.indexOf(".")).length() > 7 || !glyph.contains(".") && glyph.length() > 7) {
				allLigatureSet.add(glyph);
			}	
		}
	}
	
	public void generate() throws IOException {
		String content = readResource("template.html");
		content = content.replace("${LOOKUPS}", generateCollapsibleLookups());
		content = content.replace("${BY_UNICODE}", generateByUnicodeTable());
		content = content.replace("${BY_GLYPH}", generateByGlyphTable());
		content = content.replace("${BY_CLASS}", generateByClassTable());
		content = content.replace("${CCMP_FEATURE}", generateFeature("ccmp"));
		content = content.replace("${ISOL_FEATURE}", generateFeature("isol"));
		content = content.replace("${FINA_FEATURE}", generateFeature("fina"));
		content = content.replace("${MEDI_FEATURE}", generateFeature("medi"));
		content = content.replace("${INIT_FEATURE}", generateFeature("init"));
		content = content.replace("${RLIG_FEATURE}", generateFeature("rlig"));
		content = content.replace("${CALT_FEATURE}", generateFeature("calt"));
		content = content.replace("${VERT_FEATURE}", generateFeature("vert"));
		System.out.println(content);
	}
	
	private String generateCollapsibleLookups() {
		String lookups = "";
		for (Feature feature: file.features) {
			for (Lookup lookup : feature.lookups) {
				lookups += "\t\t\t\t$(\"#lookup-" + lookup.name + "\").accordion({ collapsible: true, header: \"h3\", active: false, autoHeight: false});\n";
			}
		}
		return lookups;
	}
	
	private String generateFeature(String name)  throws IOException {
		StringWriter out = new StringWriter();
		for (Feature feature: file.features) {
			if (feature.name.equals(name)) {
				for (Lookup lookup : feature.lookups) {
					out.write("\t<div id='lookup-" + lookup.name + "'>\n");
					out.write("\t\t<h3><a href='#'>" + lookup.name +"</a></h3>\n");
					out.write("\t\t<center>\n");
					out.write("\t\t\t<table class='substitutiontable'>\n");
					int maxCount = getMaxGroupCount(lookup) - 1;
					for (Substitution s :  lookup.substitutions) {
						out.write("\t\t\t\t<tr>\n");
						for (int i = 0; i < s.groups.size() - 1; i++) {
							Group group = s.groups.get(i);
							out.write("\t\t\t\t<td class=' " + (group.shouldReplaced?"replaceable":"nonreplaceable") + "'>\n");
							generateGroup("\t\t\t\t\t", out, group);
							out.write("\t\t\t\t</td>\n");
						}
						for (int i = s.groups.size(); i < maxCount; i++) {
							out.write("\t\t\t\t<td>\n");							
							out.write("\t\t\t\t</td>\n");
						}
						out.write("\t\t\t\t<td class='replacedby'>\n");
						generateGroup("\t\t\t\t\t", out, s.groups.get(s.groups.size()-1));
						out.write("\t\t\t\t</td>\n");
						out.write("\t\t\t\t</tr>\n");
					}
					out.write("\t\t\t</table>\n");
					out.write("\t\t</center>\n");
					out.write("\t</div>\n");
				}
			}
		}
		return out.toString();
	}
	
	private void generateGroup(String intend, Writer out, Group group) throws IOException {
		if (group.elements.size() == 1 && group.elements.get(0).startsWith("@")) {
			out.write(intend + group.elements.get(0) + "\n");
		} else {
			generateGlyphtable(intend, out, group.elements);
		}
	}
	
	private int getMaxGroupCount(Lookup lookup) {
		int count = 0;
		for (Substitution s :  lookup.substitutions) {
			count = Math.max(count, s.groups.size());
		}
		return count;
	}
	
	private String generateByUnicodeTable() throws IOException {
		StringWriter out = new StringWriter();
		String intend = "\t\t\t\t";
		for (int i = 0; i < 16*12; i++) {
			int unicodeID = 0x1800 + i;
			if (!(unicodeID == 0x180F || (unicodeID >= 0x181A && unicodeID <= 0x181F) || (unicodeID >= 0x1878 && unicodeID <= 0x187F) || unicodeID >= 0x18AB)) {
				String unicodeHex = Integer.toHexString(unicodeID).toUpperCase();
				String unicodeName = "uni" + unicodeHex;
				out.write(intend + "<tr>\n");
				
				out.write(intend + "\t<td class='byglyphcolumn'>\n");
				out.write(intend + "\t\t</center>\n");
				Vector<String> unicodeNames = new Vector<String>();
				unicodeNames.add(unicodeName);
				generateGlyphtable(intend + "\t\t\t", out, unicodeNames);
				out.write(intend + "\t\t</center>\n");
				out.write(intend + "\t</td>\n");
				
				out.write(intend + "\t<td class='byglyphcolumn'>\n");
				out.write(intend + "\t\t</center>\n");
				generateGlyphtable(intend + "\t\t\t", out, getVariants(unicodeName));
				out.write(intend + "\t\t</center>\n");
				out.write(intend + "\t</td>\n");
				
				out.write(intend + "\t<td class='byglyphcolumn'>\n");
				out.write(intend + "\t\t</center>\n");
				generateGlyphtable(intend + "\t\t\t", out, getLigatures(unicodeHex));
				out.write(intend + "\t\t</center>\n");
				out.write(intend + "\t</td>\n");
				
				out.write(intend + "\t<td class='byglyphcolumn'>\n");
				out.write(intend + "\t\t</center>\n");
				for (String className : getUsedClasses(unicodeHex, false)) {
					out.write(intend + "\t\t" + className + "<br/>\n");
				}
				out.write(intend + "\t\t</center>\n");
				out.write(intend + "\t</td>\n");
				
				out.write(intend + "\t<td class='byglyphcolumn'>\n");
				out.write(intend + "\t\t</center>\n");
				for (String lookupName : getUsedLookups(unicodeHex, false)) {
					out.write(intend + "\t\t" + lookupName + "<br/>\n");
				}
				out.write(intend + "\t\t</center>\n");
				out.write(intend + "\t</td>\n");
				
				out.write(intend + "</tr>\n");
			}
		}
		return out.toString();
	}
	
	private String generateByGlyphTable() throws IOException {
		StringWriter out = new StringWriter();
		String intend = "\t\t\t\t";
		for (String glyphName : allGlyphSet) {
			out.write(intend + "<tr>\n");
			
			out.write(intend + "\t<td class='byglyphcolumn'>\n");
			out.write(intend + "\t\t</center>\n");
			Vector<String> unicodeNames = new Vector<String>();
			unicodeNames.add(glyphName);
			generateGlyphtable(intend + "\t\t\t", out, unicodeNames);
			out.write(intend + "\t\t</center>\n");
			out.write(intend + "\t</td>\n");
			
			out.write(intend + "\t<td class='byglyphcolumn'>\n");
			out.write(intend + "\t\t</center>\n");
			for (String className : getUsedClasses(glyphName, true)) {
				out.write(className + " ");
			}
			out.write(intend + "\t\t</center>\n");
			out.write(intend + "\t</td>\n");
			
			out.write(intend + "\t<td class='byglyphcolumn'>\n");
			out.write(intend + "\t\t</center>\n");
			for (String lookupName : getUsedLookups(glyphName, true)) {
				out.write(lookupName + " ");
			}
			out.write(intend + "\t\t</center>\n");
			out.write(intend + "\t</td>\n");
			
			out.write(intend + "</tr>\n");
		}
		return out.toString();
	}
	
	private String generateByClassTable() throws IOException {
		StringWriter out = new StringWriter();
		String intend = "\t\t\t\t";
		for (String className : file.classes.keySet()) {
			out.write(intend + "<tr>\n");
			
			out.write(intend + "\t<td class='byglyphcolumn'>\n");
			out.write(intend + "\t\t</center>\n");
			out.write(intend + "\t\t\t" + className + "\n");
			out.write(intend + "\t\t</center>\n");
			out.write(intend + "\t</td>\n");
			
			out.write(intend + "\t<td class='byglyphcolumn'>\n");
			out.write(intend + "\t\t</center>\n");
			generateGlyphtable(intend + "\t\t\t", out, file.classes.get(className));
			out.write(intend + "\t\t</center>\n");
			out.write(intend + "\t</td>\n");
			
			out.write(intend + "</tr>\n");
		}
		return out.toString();
	}
	
	private void generateGlyphtable(String intend, Writer out, List<String> unicodeNames) throws IOException {
		out.write(intend + "<table class='glyphtable'>\n");
		for (String unicodeName : unicodeNames) {
			out.write(intend + "\t<tr><td class='glyph'><img src='./glyphs/" + unicodeName + ".png'/></td><td class='unicode'>" + unicodeName + "</td></tr>\n");
		}
		out.write(intend + "</table>\n");
	}
	
	private List<String> getVariants(String unicodeName) {
		Vector<String> variants = new Vector<String>();
		for (String glyph : allGlyphSet) {
			if (glyph.startsWith(unicodeName + ".") && !glyph.equals(unicodeName)) {
				variants.add(glyph);
			}
		}
		return variants;
	}
	
	private List<String> getLigatures(String unicodeHex) {
		Vector<String> ligatures = new Vector<String>();
		for (String glyph : allLigatureSet) {
			if (glyph.contains(unicodeHex)) {
				ligatures.add(glyph);
			}
		}
		return ligatures;
	}
	
	private List<String> getUsedClasses(String unicodeHex, boolean accurate) {
		Vector<String> usedClasses = new Vector<String>();
		for (String className : file.classes.keySet()) {
			if (containsUnicodeHex(file.classes.get(className), unicodeHex, accurate)) {
				usedClasses.add(0, className);
			}
		}
		Collections.sort(usedClasses);
		return usedClasses;
	}
	
	
	private List<String> getUsedLookups(String unicodeHex, boolean accurate) {
		Vector<String> usedLookups = new Vector<String>();
		
		for (Feature feature : file.features) {
			lookup: for (Lookup lookup : feature.lookups) {
				for (Substitution substitution : lookup.substitutions) {
					for (Group group : substitution.groups) {
						if (group.elements.size() == 1) {
							String element = group.elements.get(0);
							if (element.startsWith("@")) {
								if (containsUnicodeHex(file.classes.get(element), unicodeHex, accurate)) {
									usedLookups.add(lookup.name);
									continue lookup;
								}
							} else {
								if (accurate) {
									if (element.equals(unicodeHex)) {
										usedLookups.add(lookup.name);
										continue lookup;
									}
								} else {
									if (element.contains(unicodeHex)) {
										usedLookups.add(lookup.name);
										continue lookup;
									}
								}
							}
						} else {
							if (containsUnicodeHex(group.elements, unicodeHex, accurate)) {
								usedLookups.add(lookup.name);
								continue lookup;
							}
						}
					}
				}
			}
		}
		
		Collections.sort(usedLookups);
		return usedLookups;
	}
	
	private boolean containsUnicodeHex(List<String> elements, String unicodeHex, boolean accurate) {
		for (String element : elements) {
			if (accurate) {
				if (element.equals(unicodeHex)) {
					return true;
				}
			} else {
				if (element.contains(unicodeHex)) {
					return true;
				}
			}
		}
		return false;
	}
	
	private String readResource(String resource) throws IOException {
		String content = "";
		BufferedReader reader = new BufferedReader(new InputStreamReader(HTMLGenerator.class.getResourceAsStream(resource)));
		String line = null;
		while ((line = reader.readLine()) != null) {
			content += line + "\n";
		}
		reader.close();
		return content;
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
