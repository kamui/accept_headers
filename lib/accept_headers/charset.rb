require "accept_headers/acceptable"

module AcceptHeaders
  class Charset
    include Comparable
    include Acceptable

    class InvalidCharsetError < Error; end

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

    def self.parse(original_header)
      header = original_header.dup
      header.sub!(/\AAccept-Charset:\s*/, '')
      header.strip!
      return [Charset.new('iso-8859-5', q: 1)] if header.empty?
      charsets = []
      header.split(',').each do |entry|
        charset_arr = entry.split(';', 2)
        next if charset_arr[0].nil?
        charset = TOKEN_PATTERN.match(charset_arr[0])
        next if charset.nil?
        charsets << Charset.new(charset[:token], q: parse_q(charset_arr[1]))
      end
      charsets.sort! { |x,y| y <=> x }
    end
  end
end
