require "accept_headers/acceptable"

module AcceptHeaders
  class Language
    include Comparable
    include Acceptable

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
      "#{language_tag};q=#{qvalue}"
    end

    def language_tag
      "#{primary_tag}-#{subtag}"
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
  end
end
