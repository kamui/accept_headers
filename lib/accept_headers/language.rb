require "accept_headers/acceptable"

module AcceptHeaders
  class Language
    include Comparable
    include Acceptable

    class InvalidLanguageTagError < Error; end

    attr_reader :primary_tag, :subtag, :params

    def initialize(primary_tag = '*', subtag = nil, q: 1.0)
      self.primary_tag = primary_tag
      self.subtag = subtag
      self.q = q
    end

    def <=>(other)
      if q < other.q
        -1
      elsif q > other.q
        1
      elsif (primary_tag == '*' && other.primary_tag != '*') || (subtag == '*' && other.subtag != '*')
        -1
      elsif (primary_tag != '*' && other.primary_tag == '*') || (subtag != '*' && other.subtag == '*')
        1
      else
        0
      end
    end

    def primary_tag=(value)
      @primary_tag = value.strip.downcase
    end

    def subtag=(value)
      @subtag = if value.nil?
        '*'
      else
        value.strip.downcase
      end
    end

    def to_h
      {
        primary_tag: primary_tag,
        subtag: subtag,
        q: q
      }
    end

    def to_s
      qvalue = (q == 0 || q == 1) ? q.to_i : q
      "#{primary_tag}-#{subtag};q=#{qvalue}"
    end

    def match(other)
      if primary_tag == other.primary_tag && subtag == other.subtag
        true
      elsif primary_tag == other.primary_tag && subtag == '*'
        true
      elsif other.primary_tag == '*'
        true
      else
        false
      end
    end

    LANGUAGE_PATTERN = /^\s*(?<primary_tag>[\w]{1,8}|\*)(?:\s*\-\s*(?<subtag>[\w]{1,8}|\*))?\s*$/

    def self.parse(original_header)
      header = original_header.dup
      header.sub!(/\AAccept-Language:\s*/, '')
      header.strip!
      return [Language.new] if header.empty?
      languages = []
      header.split(',').each do |entry|
        language_arr = entry.split(';', 2)
        next if language_arr[0].nil?
        language_range = LANGUAGE_PATTERN.match(language_arr[0])
        next if language_range.nil?
        begin
          languages << Language.new(
            language_range[:primary_tag],
            language_range[:subtag],
            q: parse_q(language_arr[1])
          )
        rescue Error
          next
        end
      end
      languages.sort! { |x,y| y <=> x }
    end
  end
end
