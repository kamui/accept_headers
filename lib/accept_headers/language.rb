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
      @subtag = if value.nil? && primary_tag == '*'
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
      "#{primary_tag}/#{subtag};q=#{qvalue}"
    end

    def self.parse(accept)
      languages = accept.strip.split(',')
      return [Language.new] if languages.empty?
      languages.map do |entry|
        parts = entry.split(';')
        language_tag = parts.shift.split('-')
        language = Language.new(language_tag[0], language_tag[1])
        if language_tag.size > 2
          raise InvalidLanguageError.new("Unable to parse language tag")
        elsif parts.size > 2
          raise InvalidLanguageError.new("Unable to parse language tag")
        elsif parts.size == 2
          qkv = parts[1].split('=', 2)
          encoding.q = qkv[1]
        end
        language
      end.sort! { |x,y| y <=> x }
    end
  end
end
