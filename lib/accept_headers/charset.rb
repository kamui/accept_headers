require "accept_headers/acceptable"

module AcceptHeaders
  class Charset
    include Comparable
    include Acceptable

    attr_reader :charset

    def initialize(charset = '*', q: 1.0)
      self.charset = charset
      self.q = q
    end

    def <=>(other)
      q <=> other.q
    end

    def charset=(value)
      @charset = value.strip.downcase
    end

    def to_h
      {
        charset: charset,
        q: q
      }
    end

    def to_s
      qvalue = (q == 0 || q == 1) ? q.to_i : q
      "#{charset};q=#{qvalue}"
    end

    def match(other)
      if charset == other.charset
        true
      elsif other.charset == '*'
        true
      else
        false
      end
    end
  end
end
