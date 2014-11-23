require "accept_headers/encoding"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Encoding
    class Negotiator
      include Negotiatable

      def negotiate(supported)
        support, match = super(supported)
        return nil if support.nil? && match.nil?
        begin
          return Encoding.parse(support)
        rescue Encoding::Error
          return nil
        end
      end

      private
      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept-Encoding:\s*/, '')
        header.strip!
        return [Encoding.new] if header.empty?
        encodings = []
        header.split(',').each do |entry|
          begin
            encoding = Encoding.parse(entry)
            next if encoding.nil?
            encodings << encoding
          rescue Encoding::Error
            next
          end
        end
        encodings.sort! { |x,y| y <=> x }
      end
    end
  end
end
