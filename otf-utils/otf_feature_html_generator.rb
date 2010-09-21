require 'otf_feature_file_parser'

def generate_glyph_table_html(intend, glyphs)
  output = "#{intend}<table class='glyphtable'>\n"
  glyphs.sort{|x,y| x.name <=> y.name}.each do |glyph|
    output += "#{intend}\t<tr><td class='glyph'><img src='./glyphs/#{glyph.name}.png'/></td><td class='unicode'>#{glyph.name}</td></tr>\n"
  end
  output += "#{intend}</table>\n"
  return output
end

class OTFFeatureFile
  def create_unicode_table_html
    intend = "\t\t\t\t"
    output = ""
    unicodes.each do |unicode|
      output += "#{intend}<tr>\n"
              
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      output += generate_glyph_table_html(intend, [unicode.base_glyph])
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      all_glyphs = unicode.get_all_glyphs
      
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      output += generate_glyph_table_html("#{intend}\t\t\t", all_glyphs.select{|glyph| !glyph.ligature?})
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      output += generate_glyph_table_html("#{intend}\t\t\t", all_glyphs.select{|glyph| glyph.ligature?})
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      all_glyphs.map{|glyph| glyph.get_classes}.flatten.uniq.each do |klass|
        output += "#{intend}\t\t<a href='#class-#{klass.name[1..-1]}'>#{klass.name}</a><br/>\n"
      end
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      all_glyphs.map{|glyph| glyph.get_lookups}.flatten.uniq.each do |lookup|
        output += "#{intend}\t\t<a href='#lookup-#{lookup.name}'>#{lookup.name}</a><br/>\n"
      end
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      output += "#{intend}</tr>\n"
    end
    return output
  end
  
  def create_glyph_table_html
    intend = "\t\t\t\t"
    output = ""
    glyphs.sort{|x,y| x.name <=> y.name}.each do |glyph|
      output += "#{intend}<tr>\n"
              
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      output += generate_glyph_table_html(intend, [glyph])
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      glyph.get_classes.each do |klass|
        output += "#{intend}\t\t<a href='#class-#{klass.name[1..-1]}'>#{klass.name}</a><br/>\n"
      end
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      output += "#{intend}\t<td class='byglyphcolumn'>\n"
      output += "#{intend}\t\t</center>\n"
      glyph.get_lookups.each do |lookup|
        output += "#{intend}\t\t<a href='#lookup-#{lookup.name}'>#{lookup.name}</a><br/>\n"
      end
      output += "#{intend}\t\t</center>\n"
      output += "#{intend}\t</td>\n"
      
      output += "#{intend}</tr>\n"
    end
    return output
  end
end

class OTFClass
  def create_collapsible_html
    return "$(\"#class-#{name[1..-1]}\").accordion({ collapsible: true, header: \"h3\", active: false, autoHeight: false});\n";
  end
end

class OTFLookup
  def create_collapsible_html
    return "$(\"#lookup-#{name}\").accordion({ collapsible: true, header: \"h3\", active: false, autoHeight: false});\n";
  end
end

if ARGV.size == 0
  puts "Usage: ruby otf_feature_html_generator.rb monbaiti.fea"
  exit
end

parser = OTFFeatureFileParser.new
file = parser.parse_file(ARGV[0])
if file
  html = parser.get_file_content("template.html")
  html = html.sub(/\$\{COLLAPSIBLE_CLASSES\}/, "#{file.classes.map{|klass| klass.create_collapsible_html}.join("\t\t\t\t")}")
  html = html.sub(/\$\{COLLAPSIBLE_LOOKUPS\}/, "#{file.features.map{|feature| feature.lookups.map{|lookup| lookup.create_collapsible_html}}.flatten.join("\t\t\t\t")}")
  html = html.sub(/\$\{BY_UNICODE\}/, file.create_unicode_table_html)
  html = html.sub(/\$\{BY_GLYPH\}/, file.create_glyph_table_html)
  
  puts html
else
  puts "syntax error!"
end