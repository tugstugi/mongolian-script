require 'rubygems'
require "treetop"
require "polyglot"
require 'otf_feature_file'

class OTFFeatureFile
  attr_reader :glyphs, :unicodes, :classes, :features
  
  def initialize
    @glyphs = Array.new
    @unicodes = Array.new
    @classes = Array.new
    @features = Array.new
  end
  
  def get_glyph(glyphname)
    @glyphs.select{|glyph| glyph.name.eql?glyphname}.first
  end
  
  def get_unicode(hex_unicode)
    @unicodes.select{|unicode| unicode.hex_unicode.eql?hex_unicode}.first
  end
  
  def get_unicode_by_name(name)
    @unicodes.select{|unicode| unicode.name.eql?name}.first
  end
  
  def get_class(classname)
    @classes.select{|klass| klass.name.eql?classname}.first
  end
  
  def get_feature(featurename)
    @features.select{|feature| feature.name.eql?featurename}.first
  end
end

class OTFClass
  attr_reader :file, :name, :glyphs
  
  def initialize(file, name)
    @file = file
    @name = name
    @glyphs = Array.new
  end
  
  def get_lookups
    return file.features.map{|feature| feature.lookups}.flatten.select{|lookup| lookup.include?self}
  end
  
  def include?(glyph)
    return glyphs.include?glyph
  end
end

class OTFGlyph
  attr_reader :file, :name
  attr_writer :name
  
  def initialize(file, name)
    @file = file
    @name = name
  end
  
  def base?
    return !name.match(/^[^.]+$/).nil?
  end
  
  def isol?
    return !name.match(/^[a-zA-Z0-9]+[.][a-zA-Z0-9]*isol[a-zA-Z0-9]*/).nil?
  end
  
  def fina?
    return !name.match(/^[a-zA-Z0-9]+[.][a-zA-Z0-9]*fina[a-zA-Z0-9]*/).nil?
  end
  
  def medi?
    return !name.match(/^[a-zA-Z0-9]+[.][a-zA-Z0-9]*medi[a-zA-Z0-9]*/).nil?
  end
  
  def init?
    return !name.match(/^[a-zA-Z0-9]+[.][a-zA-Z0-9]*init[a-zA-Z0-9]*/).nil?
  end
  
  def var?
    return !name.match(/^[a-zA-Z0-9]+[.][a-zA-Z0-9]*var[a-zA-Z0-9]*/).nil?
  end
  
  def mvs?
    return !name.match(/^[a-zA-Z0-9]+[.][a-zA-Z0-9]*mvs[a-zA-Z0-9]*/).nil?
  end
  
  def fem?
    return !name.match(/^[a-zA-Z0-9]+[.][a-zA-Z0-9]*fem[a-zA-Z0-9]*/).nil?
  end
  
  def ligature?
    return !name.match(/^[a-zA-Z]+(18[A-F0-9][A-F0-9]){2,}/).nil?
  end
  
  def get_classes
    return file.classes.select{|klass| klass.include?self}
  end
  
  def get_lookups
    return file.features.map{|feature| feature.lookups}.flatten.select{|lookup| lookup.include?self}
  end
  
  def get_composed_unicodes
    unicodes = Array.new
    name.scan(/(18[A-F0-9][A-F0-9])+?/).flatten.each do |hex_unicode|
      unicode = @file.get_unicode(hex_unicode)
      if !unicode.nil?
        unicodes.push(unicode)
      end
    end
    return unicodes.uniq
  end
end

class OTFUnicode
  attr_reader :file, :unicode, :name, :hex_unicode
  attr_writer :name
    
  def initialize(file, unicode)
    @file = file
    @unicode = unicode
    @hex_unicode = unicode.to_s(16).upcase
    @name = "uni#{hex_unicode}"
  end
  
  def transparent?
    return [0x180A, 0x180B, 0x180C, 0x180D].include?(unicode)
  end
  
  def mongolian_letter?
    return unicode == 0x1807 || (0x1820..0x18AA).include?(unicode)
  end
  
  def base_glyph
    return file.get_glyph(name)
  end
  
  def get_all_glyphs
    return file.glyphs.select{|glyph| glyph.name.include?hex_unicode}
  end
  
  def get_ligature_glyphs
    return get_all_glyphs.select{|glyph| glyph.ligature?}
  end
  
  def get_nonligature_glyphs
    return get_all_glyphs.select{|glyph| !glyph.ligature?}
  end
  
  def get_classes
    return get_all_glyphs.map{|glyph| glyph.get_classes}.flatten.uniq
  end
  
  def get_lookups
    return get_all_glyphs.map{|glyph| glyph.get_lookups}.flatten.uniq
  end
end

class OTFFeature
  attr_reader :file, :name, :script, :lookups, :languages, :inner_features
  attr_writer :script
  
  def initialize(file, name)
    @file = file
    @name = name
    @script = nil
    @lookups = Array.new
    @languages = Hash.new
    @inner_features = Array.new
  end
  
  def get_lookup(lookupname)
    lookups.select{|lookup| lookup.name.eql?lookupname}.first
  end
end

class OTFLookup
  attr_reader :feature, :name, :lookupflag, :subtables
  attr_writer :lookupflag
  
  def initialize(feature, name)
    @feature = feature
    @name = name
    @lookupflag = nil
    @subtables = Array.new
  end
  
  def include?(glyph_or_class)
    subtables.each do |subtable|
      if subtable.include?glyph_or_class
        return true
      end
    end
    return false
  end
end

class OTFSubTable
  attr_reader :lookup, :groups, :replacedby
  attr_writer :replacedby
  
  def initialize(lookup)
    @lookup = lookup
    @groups = Array.new
    @replacedby = nil
  end
  
  def include?(glyph_or_class)
    if replacedby.include?glyph_or_class
      return true
    end
    groups.each do |group|
      if group.include?glyph_or_class
        return true
      end
    end
    return false
  end
end

class OTFGroup
  attr_reader :subtable, :elements
  
  def initialize(subtable, replaceable)
    @subtable = subtable
    @replaceable = replaceable
    @elements = Array.new
  end
  
  def replaceable?
    @replaceable
  end
  
  def include?(glyph_or_class)
    if elements.include?glyph_or_class
      return true
    end
    if glyph_or_class.instance_of?OTFGlyph
      return elements.select{|e| e.instance_of?OTFClass}.map{|klass| klass.glyphs}.flatten.include?glyph_or_class
    end
    return false
  end
end

class OTFFeatureFileParser
  
  def parse_file(filename)
    parse_string(get_file_content(filename))
  end
  
  def parse_string(source)
    syntaxParser = OTFFeatureFileSyntaxParser.new
    content = syntaxParser.parse(source)
    if (content)
      content = content.content
      
      file = OTFFeatureFile.new()
      
      content.each do |file_content|
        name = file_content[:name]
          
        if /^@/.match(name)
          # otf class definition
          klass = OTFClass.new(file, name)
          file.classes.push(klass)
          
          file_content[:glyphs].each do |glyphname|
            glyph = file.get_glyph(glyphname)
            if glyph.nil?
              glyph = OTFGlyph.new(file, glyphname)
              file.glyphs.push(glyph)
            end
            klass.glyphs.push(glyph)
          end
        else
          # otf feature definition
          feature = OTFFeature.new(file, name)
          file.features.push(feature)
          
          # some features have no lookup but subtables. i.e. see vert feature of Baiti.
          dummy_lookup = nil;
          language = nil;
          
          file_content[:feature_body][0].each do |feature_body_element|
            if feature_body_element[:script]
              feature.script = feature_body_element[:script]
            end
            if feature_body_element[:inner_feature]
              feature.inner_features.push(feature_body_element[:inner_feature])
            end
            
            if feature_body_element[:lookup_flag]
              if dummy_lookup.nil?
                dummy_lookup = OTFLookup.new(feature, feature.name)
                feature.lookups.push(dummy_lookup)
              end
              dummy_lookup.lookupflag = feature_body_element[:lookup_flag]
            end
            
            if feature_body_element[:subtable]
              if dummy_lookup.nil?
                dummy_lookup = OTFLookup.new(feature, feature.name)
                feature.lookups.push(dummy_lookup)
              end
              
              subtable = create_subtable(file, feature, dummy_lookup, feature_body_element[:subtable])
              dummy_lookup.subtables.push(subtable)
            end
            
            if feature_body_element[:lookup]
              lookup = OTFLookup.new(feature, feature_body_element[:lookup])
              feature.lookups.push(lookup)
              if language
                feature.languages[language].push(lookup)
              end
              
              feature_body_element[:lookup_body][0].each do |lookup_body_element|
                if lookup_body_element[:lookup_flag]
                  lookup.lookupflag = lookup_body_element[:lookup_flag]
                end
                
                if lookup_body_element[:subtable]
                  subtable = create_subtable(file, feature, lookup, lookup_body_element[:subtable])
                  lookup.subtables.push(subtable)
                end
              end
            end
            
            if feature_body_element[:language]
              language = feature_body_element[:language]
              feature.languages[language] = Array.new
              if !feature_body_element[:exclude_default]
                feature.lookups.each do |lookup|
                  feature.languages[language].push(lookup)
                end
              end
            end
            
            if feature_body_element[:empty_lookup] && language
              lookup = feature.get_lookup(feature_body_element[:empty_lookup])
              if lookup
                feature.languages[language].push(lookup)
              end
            end
          end
        end
      end
      
      unicode_range = (0x1800..0x180E).to_a
      unicode_range = unicode_range.concat((0x1810..0x1819).to_a)
      unicode_range = unicode_range.concat((0x1820..0x1877).to_a)
      unicode_range = unicode_range.concat((0x1880..0x18AA).to_a)
      unicode_range = unicode_range.concat([0x20, 0x202F])
      
      unicode_range.each do |i|
        unicode = OTFUnicode.new(file, i)
        file.unicodes.push(unicode)
        if unicode.base_glyph.nil?
          glyph = OTFGlyph.new(file, "uni#{unicode.hex_unicode}")
          # for space       
          if i == 0x20
            unicode.name = "space"
            glyph = OTFGlyph.new(file, "space")
          end
          file.glyphs.push(glyph)
        end
      end
      
      return file
    end
    
    return nil
  end
  
  def create_subtable(file, feature, lookup, subtable_body)
    subtable = OTFSubTable.new(lookup)
    
    subtable_body[0].each do |group_element|
      subtable.groups.push(create_group(file, feature, lookup, subtable, group_element.flatten[0]))
    end
    
    subtable.replacedby = create_group(file, feature, lookup, subtable, subtable_body[1])
    
    return subtable
  end
  
  def create_group(file, feature, lookup, subtable, group_body)
    group = nil;
    if group_body[:replaceable_glyphs]
      group = OTFGroup.new(subtable, true)
      group_elements = group_body[:replaceable_glyphs][0]
    else
      group = OTFGroup.new(subtable, false)
      group_elements = group_body[:glyphs][0]
    end
    
    group_elements.each do |e|
      if /^@/.match(e)
        klass = file.get_class(e)
        if klass
          group.elements.push(klass)
        end
      else
        glyph = file.get_glyph(e)
        if glyph.nil?
          glyph = OTFGlyph.new(file, e)
          file.glyphs.push(glyph)
        end
        group.elements.push(glyph)
      end
    end
    
    return group
  end
  
  def get_file_content(filename)
    content = '';
    f = File.open(filename, "r")
    f.each_line do |line|
      content += line
    end
    return content
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size == 0
    puts "Usage: ruby otf_feature_file_parser.rb monbaiti.fea"
    exit!
  end
  
  parser = OTFFeatureFileParser.new
  file = parser.parse_file(ARGV[0])
  if file
    puts "success"
  else
    puts "syntax error!"
  end
end
