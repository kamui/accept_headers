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

    def match(other)
      if encoding == other.encoding
        true
      elsif other.encoding == '*'
        true
      else
        false
      end
    end

    def self.parse(original_header)
      header = original_header.dup
      header.sub!(/\AAccept-Encoding:\s*/, '')
      header.strip!
      return [Charset.new] if header.empty?
      encodings = []
      header.split(',').each do |entry|
        encoding_arr = entry.split(';', 2)
        next if encoding_arr[0].nil?
        encoding = TOKEN_PATTERN.match(encoding_arr[0])
        next if encoding.nil?
        encodings << Encoding.new(encoding[:token], q: parse_q(encoding_arr[1]))
      end
      encodings.sort! { |x,y| y <=> x }
    end
  end
end
