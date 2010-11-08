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
  
  def create_class_table_html
    return classes.sort{|x,y| x.name <=> y.name}.map{|klass| klass.create_html}.join
  end
end

class OTFClass
  def create_collapsible_html
    return "$(\"#class-#{name[1..-1]}\").accordion({ collapsible: true, header: \"h3\", active: false, autoHeight: false});\n"
  end
  
  def create_html
    output = ""
    output += "\t<div id='class-#{name[1..-1]}'>\n"
    output += "\t\t<h3><a name='class-#{name[1..-1]}'>#{name}</a></h3>\n"
    output += "\t\t<center>\n"
    output += "\t\t\t<table class='classtable'>\n"
    output += "\t\t\t\t<tr>\n"
    output += "\t\t\t\t\t<th>Glyphs</th><th>Lookups</th>\n"
    output += "\t\t\t\t</tr>\n"
    output += "\t\t\t\t<tr>\n"
    output += "\t\t\t\t\t<td class='classtable_glyphs'>\n"
    output += "\t\t\t\t\t\t<center>\n"
    output += generate_glyph_table_html("\t\t\t\t\t\t\t", glyphs)
    output += "\t\t\t\t\t\t</center>\n"
    output += "\t\t\t\t\t</td>\n"
    output += "\t\t\t\t\t<td class='classtable_lookups'>\n"
    output += "\t\t\t\t\t\t"
    get_lookups.each do |lookup|
      output += "<a href='#lookup-#{lookup.name}'>#{lookup.name}</a><br/>\n"
    end
    output += "\t\t\t\t\t</td>\n"
    output += "\t\t\t\t</tr>\n"     
    output += "\t\t\t</table>\n"
    output += "\t\t</center>\n"
    output += "\t</div>\n"
    return output
  end
end

class OTFFeature
  def create_html
    lookups.map{|lookup| lookup.create_html}.join
  end
end

class OTFLookup
  def create_collapsible_html
    return "$(\"#lookup-#{name}\").accordion({ collapsible: true, header: \"h3\", active: false, autoHeight: false});\n"
  end
  
  def create_html
    output = ""
    output += "\t<div id='lookup-#{name}'>\n"
    output += "\t\t<h3><a name='lookup-#{name}'>#{name}</a></h3>\n"
    output += "\t\t<center>\n"
    output += "\t\t\t<table class='substitutiontable'>\n"
    max_column_count = subtables.map{|subtable| subtable.groups.size}.max
    subtables.each do |subtable|
      output += subtable.create_html(max_column_count)
    end
    output += "\t\t\t</table>\n"
    output += "\t\t</center>\n"
    output += "\t</div>\n"
  end
end

class OTFSubTable
  def create_html(max_column_count)
    output = ""
    output += "\t\t\t\t<tr>\n"
    output += groups.map{|group| group.create_html}.join
    for i in groups.size..max_column_count
      output += "\t\t\t\t\t<td>\n"    
      output += "\t\t\t\t\t</td>\n"
    end
    output += replacedby.create_html("replacedby")
    output += "\t\t\t\t</tr>\n"
    return output
  end
end

class OTFGroup
  def create_html(type=nil)
    output = ""
    if type.nil?
      if subtable.lookup.feature.name.eql?"calt"
        if replaceable?
          type = "replaceable"
        else
          type = "nonreplaceable"
        end
      else
        type = "replaceable"
      end
    end
    output += "\t\t\t\t\t<td class='#{type}'>\n"
    if elements.first.instance_of?OTFClass
      output += "\t\t\t\t\t<a href='#class-#{elements.first.name[1..-1]}'>#{elements.first.name}</a>\n"
    else
      output += generate_glyph_table_html("\t\t\t\t\t", elements)
    end
    output += "\t\t\t\t\t</td>\n"
    return output
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
  html = html.sub(/\$\{CLASSES\}/, file.create_class_table_html)
  html = html.sub(/\$\{CCMP_FEATURE\}/, file.get_feature("ccmp").create_html)
  html = html.sub(/\$\{ISOL_FEATURE\}/, file.get_feature("isol").create_html)
  html = html.sub(/\$\{FINA_FEATURE\}/, file.get_feature("fina").create_html)
  html = html.sub(/\$\{MEDI_FEATURE\}/, file.get_feature("medi").create_html)
  html = html.sub(/\$\{INIT_FEATURE\}/, file.get_feature("init").create_html)
  html = html.sub(/\$\{RLIG_FEATURE\}/, file.get_feature("rlig").create_html)
  html = html.sub(/\$\{CALT_FEATURE\}/, file.get_feature("calt").create_html)
  html = html.sub(/\$\{VERT_FEATURE\}/, file.get_feature("vert").create_html)
  
  puts html
else
  puts "syntax error!"
end