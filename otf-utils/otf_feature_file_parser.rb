require 'rubygems'
require "treetop"
require "polyglot"
require 'otf_feature_file'

class OTFFeatureFile
  def initialize
    @glyphs = Array.new
    @classes = Array.new
    @features = Array.new
  end
  
  def glyphs
    @glyphs
  end
  
  def classes
    @classes
  end
  
  def features
    @features
  end
end

class Class
  def initialize(file, name)
    @file = file
    @name = name
    @glyphs = Array.new
  end
  
  def name
    @name
  end
  
  def glyphs
    @glyphs
  end
end

class Glyph
  def initialize(file, name)
    @file = file
    @name = name
  end
  
  def name
    @name
  end
end

class Feature
  def initialize(file, name)
    @file = file
    @name = name
    @script = nil
    @lookups = Array.new
    
    # to be ignored
    @inner_features = Array.new
  end
  
  def name
    @name
  end
  
  def script
    @script
  end
  
  def script=(script)
     @script = script
  end
  
  def lookups
    @lookups
  end
  
  # to be ignored
  def inner_features
    @inner_features
  end
end

class Lookup
  def initialize(feature, name)
    @feature = feature
    @name = name
    @subtables = Array.new
    @languages = Array.new
  end
  
  def name
    @name
  end
  
  def lookupflag
    @lookupflag
  end
  
  def lookupflag=(lookupflag)
    @lookupflag = lookupflag
  end
  
  def subtables
    @subtables
  end
  
  def languages
    @languages
  end
end

class SubTable
  def initialize(lookup)
    @lookup = lookup
    @groups = Array.new
    @replacedby = nil
  end
  
  def groups
    @groups
  end
  
  def replacedby
    @replacedby
  end
  
  def replacedby=(replacedby)
    @replacedby = replacedby
  end
end

class Group
  def initialize(subtable, replaceable)
    @subtable = subtable
    @replaceable = replaceable
    @elements = Array.new
  end
  
  def elements
    @elements
  end
  
  def replaceable?
    @replaceable
  end
end

class InnerFeature
  def initialize(feature, name)
    @feature = feature
    @name = name
  end
end

class OTFFeatureFileParser
  
  def parse(source)
    syntaxParser = OTFFeatureFileSyntaxParser.new
    content = syntaxParser.parse(source)
    if (content)
      content = content.content
      
      file = OTFFeatureFile.new()
      
      content.each do |element|
        name = element[:name]
          
        if /^@/.match(name)
          # otf class definition
          klass = Class.new(file, name)
          file.classes.push(klass)
          
          element[:glyphs].each do |glyphname|
            glyph = add_and_get_glyph(file, glyphname)
            klass.glyphs.push(glyph)
          end
        else
          # otf feature definition
          feature = Feature.new(file, name)
          file.features.push(feature)
          
          # some features have no lookup but subtables. i.e. see vert feature of Baiti.
          dummy_lookup = nil;
          language = nil;
          
          element[:feature_body][0].each do |feature_body_element|
            if feature_body_element[:script]
              feature.script = feature_body_element[:script]
            end
            if feature_body_element[:inner_feature]
              feature.inner_features.push(feature_body_element[:inner_feature])
            end
            
            if feature_body_element[:lookup_flag]
              if dummy_lookup == nil
                dummy_lookup = Lookup.new(feature, feature.name)
                feature.lookups.push(dummy_lookup)
              end
              dummy_lookup.lookupflag = feature_body_element[:lookup_flag]
            end
            
            if feature_body_element[:subtable]
              if dummy_lookup == nil
                dummy_lookup = Lookup.new(feature, feature.name)
                feature.lookups.push(dummy_lookup)
              end
              
              subtable = create_subtable(file, feature, dummy_lookup, feature_body_element[:subtable])
              dummy_lookup.subtables.push(subtable)
            end
            
            if feature_body_element[:lookup]
              lookup = Lookup.new(feature, feature_body_element[:lookup])
              feature.lookups.push(lookup)
              if language
                lookup.languages.push(language)
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
              if !feature_body_element[:exclude_default]
                feature.lookups.each do |lookup|
                  lookup.languages.push(language)
                end
              end
            end
            
            if feature_body_element[:empty_lookup] && language
              lookup = get_lookup(feature, feature_body_element[:empty_lookup])
              if lookup
                lookup.languages.push(language)
              end
            end
          end
        end
      end
      
      return file
    end
    
    return nil
  end
  
  def create_subtable(file, feature, lookup, subtable_body)
    subtable = SubTable.new(lookup)
    
    for i in 0..subtable_body[0].size-1
      group = create_group(file, feature, lookup, subtable, subtable_body[0][i].flatten[0])
      subtable.groups.push(group)
    end
    
    group = create_group(file, feature, lookup, subtable, subtable_body[1])
    subtable.replacedby = group
    
    return subtable
  end
  
  def create_group(file, feature, lookup, subtable, group_body)
    group = nil;
    if group_body[:replaceable_glyphs]
      group = Group.new(subtable, true)
      group_elements = group_body[:replaceable_glyphs][0]
    else
      group = Group.new(subtable, false)
      group_elements = group_body[:glyphs][0]
    end
    
    group_elements.each do |e|
      #puts e
      if /^@/.match(e)
        klass = get_class(file, e)
        if klass
          group.elements.push(klass)
        end
      else
        glyph = add_and_get_glyph(file, e)
        group.elements.push(glyph)
      end
    end
    
    return group
  end
  
  def get_class(file, classname)
    file.classes.each do |klass|
      if klass.name.eql?classname
        return klass
      end
    end
    return nil
  end
  
  def get_lookup(feature, lookupname) 
    feature.lookups.each do |lookup|
      if lookup.name.eql?lookupname
        return lookup
      end
    end
    return nil
  end
  
  def add_and_get_glyph(file, glyphname)
    file.glyphs.each do |glyph|
      if glyph.name().eql?glyphname
        return glyph
      end
    end
    glyph = Glyph.new(file, glyphname)
    file.glyphs.push(glyph)
    return glyph
  end
end
