require 'otf_feature_file_parser'

def generate_group(group)
  output = group.elements.map{|e| e.name}.join(" ");
  if group.elements.size > 1
    output = "[#{output}]"
  end
  if group.replaceable?
    output += "'"
  end
  return output
end

def generate_subtable(subtable)
  output = "\t\tsub #{subtable.groups.map{|group| generate_group(group)}.join(" ")} by #{generate_group(subtable.replacedby)};\n"
  return output
end

if ARGV.size == 0
  puts "Usage: ruby otf_feature_file_generator.rb monbaiti.fea"
  exit
end

parser = OTFFeatureFileParser.new
file = parser.parse_file(ARGV[0])
if file
  output = ''
  
  file.classes.each do |klass|
    output += "#{klass.name}=[#{klass.glyphs.map{|glyph| glyph.name}.join(" ")}];\n"
  end
  
  file.features.each do |feature|
    output += "\n\nfeature #{feature.name} {\n"
    
    if feature.script
      output += "\tscript #{feature.script};\n"
    end
    
    feature.inner_features.each do |inner_feature|
      output += "\tfeature #{inner_feature};\n"
    end
    
    if feature.lookups.size == 1 && (feature.lookups.first).name.eql?(feature.name)
      # inner subtables
      
      if feature.lookups.first.lookupflag
        output += "\tlookupflag #{feature.lookups.first.lookupflag};\n"
      end
      feature.lookups.first.subtables.each do |subtable|
        output += generate_subtable(subtable)
      end
      
      feature.languages.each_key do |language|
        output += "\tlanguage #{language};\n";
      end
    else
      feature.lookups.each do |lookup|
        output += "\tlookup #{lookup.name} {\n"
        if lookup.lookupflag
          output += "\t\tlookupflag #{lookup.lookupflag};\n"
        end
        lookup.subtables.each do |subtable|
          output += generate_subtable(subtable)
        end
        output += "\t} #{lookup.name};\n"
      end
      
      feature.languages.each_key do |language|
        output += "\tlanguage #{language} exclude_dflt;\n";
        feature.languages[language].each do |lookup|
          output += "\t\tlookup #{lookup.name};\n"
        end
      end
    end
    
    output += "} #{feature.name};\n\n"
  end
  
  puts output
  
else
  puts "syntax error!"
end