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

class OTFMockEngine
  attr_reader :file
  
  def initialize(file)
    @file = file
  end
  
  def convert(unicode_string)
    unicodes = to_glyph_names(unicode_string).map{|name| file.get_unicode_by_name(name)}
    glyphs = Array.new
    for i in 0..unicodes.length-1
      glyph = unicodes[i].base_glyph
      
      glyph.isol = false
      glyph.fina = false
      glyph.medi = false
      glyph.init = false
      
      is_prev_letter = is_letter?(unicodes, i, -1)
      is_current_letter = is_letter?(unicodes, i, 0)
      is_next_letter = is_letter?(unicodes, i, -1)
      
      puts is_prev_letter.to_s + " " + is_current_letter.to_s + " " + is_next_letter.to_s
      
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
      puts glyph.fina?
      glyphs.push(glyph)
    end
    return glyphs
  end
  
  private
  
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
  if ARGV.size == 0
    puts "Usage: ruby otf_mock_engine.rb monbaiti.fea mongolian_unicode_string"
    exit!
  end
  
  parser = OTFFeatureFileParser.new
  file = parser.parse_file(ARGV[0])
  if file
    engine = OTFMockEngine.new(file)
    
    engine.convert("ᠮᠣᠩᠭᠣᠯ ").each do |unicode|
      puts unicode.name
    end
  else
    puts "syntax error!"
  end
end