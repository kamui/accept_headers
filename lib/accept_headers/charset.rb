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

    def self.parse(accept_charset)
      # TODO: If no * charset, add iso-8859-5;q=1
      charsets = accept_charset.strip.split(',')
      return [Charset.new] if charsets.empty?
      charsets.map do |entry|
        parts = entry.split(';')
        charset = Charset.new(parts[0])
        if parts.size > 2
          raise InvalidCharsetError.new("Unable to parse charset")
        elsif parts.size == 2
          qkv = parts[1].split('=', 2)
          charset.q = qkv[1]
        end
        charset
      end.sort! { |x,y| y <=> x }
    end
  end
end
