require "accept_headers/encoding"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Encoding
    class Negotiator
      include Negotiatable

      private
      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept-Encoding:\s*/, '')
        header.strip!
        return [Encoding.new] if header.empty?
        encodings = []
        header.split(',').each do |entry|
          encoding_arr = entry.split(';', 2)
          next if encoding_arr[0].nil?
          encoding = Encoding::ENCODING_PATTERN.match(encoding_arr[0])
          next if encoding.nil?
          encodings << Encoding.new(encoding[:encoding], q: parse_q(encoding_arr[1]))
        end
        encodings.sort! { |x,y| y <=> x }
      end
    end
  end
end
