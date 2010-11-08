require 'otf_feature_file_parser'

class OTFFeatureFile
  def to_s
    return classes.join + "\n\n" + features.join("\n\n")
  end
end

class OTFFeature
  def to_s
    output = "feature #{name} {\n"
    if script
      output += "\tscript #{script};\n"
    end
    inner_features.each do |inner_feature|
      output += "\tfeature #{inner_feature};\n"
    end
    if lookups.size == 1 && (lookups.first).name.eql?(name)
      # inner subtables
      if lookups.first.lookupflag
        output += "\tlookupflag #{lookups.first.lookupflag};\n"
      end
      output += lookups.first.subtables.join
      languages.each_key do |language|
        output += "\tlanguage #{language};\n";
      end
    else
      output += lookups.join
      languages.each_key do |language|
        output += "\tlanguage #{language} exclude_dflt;\n";
        languages[language].each do |lookup|
          output += "\t\tlookup #{lookup.name};\n"
        end
      end
    end
    output += "} #{name};\n"
    return output
  end
end

class OTFClass
  def to_s
    return "#{name}=[#{glyphs.map{|glyph| glyph.name}.join(" ")}];\n"
  end
end

class OTFLookup
  def to_s
    output = "\tlookup #{name} {\n"
    if lookupflag
      output += "\t\tlookupflag #{lookupflag};\n"
    end
    output += subtables.join
    output += "\t} #{name};\n"
    return output
  end
end

class OTFSubTable
  def to_s
    return "\t\tsub #{groups.map{|group| group.to_s}.join(" ")} by #{replacedby.to_s};\n"
  end
end

class OTFGroup
  def to_s
    output = elements.map{|e| e.name}.join(" ");
    if elements.size > 1
      output = "[#{output}]"
    end
    if replaceable?
      output += "'"
    end
    return output    
  end
end

if ARGV.size == 0
  puts "Usage: ruby otf_feature_file_generator.rb monbaiti.fea"
  exit
end

parser = OTFFeatureFileParser.new
file = parser.parse_file(ARGV[0])
if file
  puts file.to_s
else
  puts "syntax error!"
end