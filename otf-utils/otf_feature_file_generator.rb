require 'otf_feature_file_parser'

def get_file_content(filename)
  content = '';
  f = File.open(filename, "r")
  f.each_line do |line|
    content += line
  end
  return content
end

def generate_group(group)
  output = ""
  if group.elements.size == 1
    output = group.elements[0].name
  else
    output = "["
    group.elements.each do |element|
      output += element.name + " "
    end
    output += "]"
  end
  if group.replaceable?
    output += "'"
  end
  return output
end

def generate_subtable(subtable)
  output = ""
  output += "\t\t\tsub "
  subtable.groups.each do |group|
    output += generate_group(group) + " "
  end
  output += "by "
  output += generate_group(subtable.replacedby)
  output += ";\n"
  return output
end

if ARGV.size == 0
  puts "Usage: ruby otf_feature_file_generator.rb monbaiti.fea"
  exit
end

content = get_file_content(ARGV[0])

parser = OTFFeatureFileParser.new
file = parser.parse(content)
if file
  output = ''
  
  file.classes.each do |klass|
    output = "#{klass.name}=["
    klass.glyphs.each do |glyph|
      output += "#{glyph.name} "
    end
    output += "];\n"
  end
  
  file.features.each do |feature|
    output += "\n\nfeature #{feature.name} {\n"
    
    if feature.script
      output += "\tscript #{feature.script};\n"
    end
    
    feature.inner_features.each do |inner_feature|
      output += "\tfeature #{inner_feature};\n"
    end
    
    if feature.lookups.size == 1 && (feature.lookups[0]).name.eql?(feature.name)
      # inner subtables
      
      if feature.lookups[0].lookupflag
        output += "\t\tlookupflag #{feature.lookups[0].lookupflag};\n"
      end
      feature.lookups[0].subtables.each do |subtable|
        output += generate_subtable(subtable)
      end
    else
      feature.lookups.each do |lookup|
        output += "\t\tlookup #{lookup.name} {\n"
        if lookup.lookupflag
          output += "\t\t\tlookupflag #{lookup.lookupflag};\n"
        end
        lookup.subtables.each do |subtable|
          output += generate_subtable(subtable)
        end
        output += "\t\t} #{lookup.name};\n"
      end
    end
    
    output += "} #{feature.name};\n\n"
  end
  
  puts output
  
else
  puts "syntax error!"
end