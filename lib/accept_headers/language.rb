require "accept_headers/acceptable"

module AcceptHeaders
  class Language
    include Comparable
    include Acceptable

    attr_reader :primary_tag, :subtag

    LANGUAGE_TAG_PATTERN = /^\s*(?<primary_tag>[\w]{1,8}|\*)(?:\s*\-\s*(?<subtag>[\w]{1,8}|\*))?\s*$/

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
      "#{language_tag};q=#{qvalue}"
    end

    def language_tag
      if primary_tag == '*' && (subtag.nil? || subtag == '*')
        '*'
      else
        "#{primary_tag}-#{subtag}"
      end
    end

    def match(language_tag_string)
      match_data = LANGUAGE_TAG_PATTERN.match(language_tag_string)
      if !match_data
        false
      elsif primary_tag == match_data[:primary_tag] && subtag == match_data[:subtag]
        true
      elsif primary_tag == match_data[:primary_tag] && subtag == '*'
        true
      elsif primary_tag == '*'
        true
      else
        false
      end
    end

    def self.parse(header)
      return nil if header.nil?
      header.strip!
      language_string, q_string = header.split(';', 2)
      raise Error if language_string.nil?
      language_range = LANGUAGE_TAG_PATTERN.match(language_string)
      raise Error if language_range.nil?
      Language.new(
        language_range[:primary_tag],
        language_range[:subtag],
        q: parse_q(q_string)
      )
    end
  end
end
