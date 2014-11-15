require "accept_headers/charset"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Charset
    class Negotiator
      include Negotiatable

      private
      def parse(original_header)
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
end
