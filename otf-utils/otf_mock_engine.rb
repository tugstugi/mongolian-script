require 'otf_feature_file_parser'

class OTFGlyph
  attr_writer :isol, :fina, :medi, :init
  
  def isol?
    return @isol
  end
  
  def fina?
    return @fina
  end
  
  def medi?
    return @medi
  end
  
  def init?
    return @init
  end
end

class OTFFeature
  def replace(glyphs)
    lookups.each do |lookup|
      lookup.replace(glyph)
    end
  end
end

class OTFLookup
  def replace(glyphs)
    subtables.each do |subtable|
      subtable.replace(glyphs)
    end
  end
end

class OTFSubTable
  def match?(glyphs, pos)
    if pos + groups.length > glyphs.length
      return false
    end
    if glyphs[pos].respond_to?("#{lookup.feature.name}?")
      return false unless glyphs[pos].send("#{lookup.feature.name}?")
    end
    for i in 0...groups.length
      return false unless groups[i].include?(glyphs[pos+i])
    end
    return true
  end
  
  def replace_by_pos(glyphs, pos)
    return unless match?(glyphs, pos)
    if groups.select{|g| g.replaceable?}.size > 0
      # calt
      # TODO
    elsif groups.size == 1
      group = groups.first
      glyph = glyphs[pos]
      if group.elements.index(glyph)
        glyphs[pos] = replacedby.elements[group.elements.index(glyph)]
      else
        # class
        glyphs[pos] = replacedby.elements.first.glyphs[group.elements.first.glyphs.index(glyph)]
      end
    elsif
      glyphs[pos...pos+groups.length] = replacedby.elements.first
    end
  end
  
  def replace(glyphs)
    i = 0
    while i < glyphs.length
      replace_by_pos(glyphs, i)
      i = i + 1
    end
  end
end

class OTFMockEngine
  attr_reader :file
  
  def initialize(file)
    @file = file
  end
  
  def convert(unicode_string, language="MNG")
    unicodes = to_glyph_names(unicode_string).map{|name| file.get_unicode(name)}
    
    glyphs = Array.new
    for i in 0..unicodes.length-1
      glyph = unicodes[i].base_glyph
      
      glyph.isol = false
      glyph.fina = false
      glyph.medi = false
      glyph.init = false
      
      is_prev_letter = is_letter?(unicodes, i, -1)
      is_current_letter = is_letter?(unicodes, i, 0)
      is_next_letter = is_letter?(unicodes, i, 1)
      
      if is_current_letter       
        if !is_prev_letter && is_next_letter
          glyph.init = true
        elsif is_prev_letter && !is_next_letter
          glyph.fina = true
        elsif is_prev_letter && is_next_letter
          glyph.medi = true
        elsif !is_prev_letter && !is_next_letter
          glyph.isol = true
        end
      end
      
      glyphs.push(glyph)
    end
    
    ["isol", "fina", "medi", "init", "rlig", "calt"].each do |featurename|
      feature = file.get_feature(featurename)
      lookups = feature.languages[language]
      lookups.each do |lookup|
        lookup.replace(glyphs)
      end
    end
    
    return glyphs
  end
  
  def is_letter?(unicodes, pos, direction)
    while(true)
      if pos == 0 && direction < 0
        return false
      end
      pos += direction
      if pos >= unicodes.length
        return false
      end
      if unicodes[pos].transparent?
        # do nothing
      else
        return unicodes[pos].mongolian_letter?
      end
    end
  end

  def to_glyph_name(s)
  	if s.eql?(" ")
  		return "space"
  	end
  	if s.length == 3
  		return "uni" + (((((s[0].to_i & 0xF) << 4) | ((s[1].to_i >> 2) & 0xF)) << 8) | (((s[1].to_i & 0x3) << 6) | (s[2].to_i & 0x3F))).to_s(16).upcase
  	end
  	return s
  end
  
  def to_glyph_names(unicode_string)	
  	return unicode_string.split(//mu).map{|s| to_glyph_name(s)}
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size != 3
    puts "Usage: ruby otf_mock_engine.rb monbaiti.fea glyphs_directory mongolian_unicode_string"
    exit!
  end
  
  parser = OTFFeatureFileParser.new
  file = parser.parse_file(ARGV[0])
  if file
    engine = OTFMockEngine.new(file)
    
    puts "convert " + engine.convert(ARGV[2]).map{|g| "#{ARGV[1]}/#{g.name}.png"}.join(" ") + " -append output.png"
  else
    puts "syntax error!"
  end
end