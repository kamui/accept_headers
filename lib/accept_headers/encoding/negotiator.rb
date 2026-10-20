require "accept_headers/encoding"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Encoding
    class Negotiator
      include Negotiatable

      ENCODING_PATTERN = /\A[ \t]*(?<encoding>[A-Za-z0-9!#$%&'*+.^_`|~\-]+)[ \t]*\z/
      HEADER_PREFIX = 'Accept-Encoding:'

      def negotiate(supported)
        supported = [*supported]
        identity = Encoding.new('identity')
        explicit_identity = list.any? { |part| part.encoding == 'identity' }
        candidates = explicit_identity ? supported : supported.reject { |support| identity.match(support) }
        support, = super(candidates)
        return Encoding.new(support) if support
        return nil if explicit_identity || !supported.any? { |value| identity.match(value) }
        return nil if list.any? { |part| part.encoding == '*' && part.q.zero? }
        identity
      end

      private
      def parse(header)
        if header && header.sub(/\A#{HEADER_PREFIX}\s*/i, '').strip.empty?
          [Encoding.new('identity')]
        else
          super
        end
      end

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
