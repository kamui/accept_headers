require "accept_headers/acceptable"

module AcceptHeaders
  class Encoding
    include Comparable
    include Acceptable

    attr_reader :encoding

    def initialize(encoding = '*', q: 1.0)
      self.encoding = encoding
      self.q = q
    end

    def <=>(other)
      q <=> other.q
    end

    def encoding=(value)
      @encoding = value.strip.downcase
    end

    def to_h
      {
        encoding: encoding,
        q: q
      }
    end

    def to_s
      qvalue = (q == 0 || q == 1) ? q.to_i : q
      "#{encoding};q=#{qvalue}"
    end

    def match(encoding_string)
      match_data = Negotiator::ENCODING_PATTERN.match(encoding_string)
      if !match_data
        false
      elsif encoding == match_data[:encoding]
        true
      elsif match_data[:encoding] == 'identity'
        true
      elsif encoding == '*'
        true
      else
        false
      end
    end
  end
end
