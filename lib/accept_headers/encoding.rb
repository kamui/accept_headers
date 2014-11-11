require "accept_headers/acceptable"

module AcceptHeaders
  class Encoding
    include Comparable
    include Acceptable

    class InvalidEncodingError < Error; end

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

    def self.parse(accept_encoding)
      encodings = accept_encoding.strip.split(',')
      return [Encoding.new] if encodings.empty?
      encodings.map do |entry|
        parts = entry.split(';')
        encoding = Encoding.new(parts[0])
        if parts.size > 2
          raise InvalidEncodingError.new("Unable to parse encoding")
        elsif parts.size == 2
          qkv = parts[1].split('=', 2)
          encoding.q = qkv[1]
        end
        encoding
      end.sort! { |x,y| y <=> x }
    end
  end
end
