require "accept_headers/language"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Language
    class Negotiator
      include Negotiatable

      LANGUAGE_TAG_PATTERN = /\A[ \t]*(?<primary_tag>[A-Za-z]{1,8}|\*)(?:-(?<subtag>[A-Za-z0-9]{1,8}(?:-[A-Za-z0-9]{1,8})*))?[ \t]*\z/
      SUPPORTED_LANGUAGE_TAG_PATTERN = /\A[A-Za-z]{1,8}(?:-[A-Za-z0-9]{1,8})*\z/
      HEADER_PREFIX = 'Accept-Language:'

      def negotiate(supported)
        support, match = super(supported)
        return nil if support.nil? && match.nil?
        begin
          return parse(support).first
        rescue Language::Error
          return nil
        end
      end

      private
      def valid_supported_value?(value)
        SUPPORTED_LANGUAGE_TAG_PATTERN.match(value.b.strip)
      end

      def no_header
        [Language.new]
      end

      def parse_item(header)
        return nil if header.nil?
        header.strip!
        language_string, q_string = header.split(';', 2)
        raise Error if language_string.nil?
        language_range = LANGUAGE_TAG_PATTERN.match(language_string)
        raise Error if language_range.nil? || (language_range[:primary_tag] == '*' && language_range[:subtag])
        Language.new(
          language_range[:primary_tag],
          language_range[:subtag],
          q: parse_q(q_string)
        )
      end
    end
  end
end
