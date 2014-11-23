require "accept_headers/encoding"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Encoding
    class Negotiator
      include Negotiatable

      ENCODING_PATTERN = /^\s*(?<encoding>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*$/
      HEADER_PREFIX = 'Accept-Encoding:'

      def negotiate(supported)
        support, match = super(supported)
        return nil if support.nil? && match.nil?
        begin
          return parse(support).first
        rescue Encoding::Error
          return nil
        end
      end

      private
      def no_header
        [Encoding.new]
      end

      def parse_item(header)
        return nil if header.nil?
        header.strip!
        encoding_string, q_string = header.split(';', 2)
        raise Error if encoding_string.nil?
        encoding = ENCODING_PATTERN.match(encoding_string)
        raise Error if encoding.nil?
        Encoding.new(encoding[:encoding], q: parse_q(q_string))
      end
    end
  end
end
