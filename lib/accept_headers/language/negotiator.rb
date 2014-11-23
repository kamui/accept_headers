require "accept_headers/language"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Language
    class Negotiator
      include Negotiatable

      LANGUAGE_TAG_PATTERN = /^\s*(?<primary_tag>[\w]{1,8}|\*)(?:\s*\-\s*(?<subtag>[\w]{1,8}|\*))?\s*$/
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
      def no_header
        [Language.new]
      end

      def parse_item(header)
        return nil if header.nil?
        header.strip!
        language_string, q_string = header.split(';', 2)
        raise Error if language_string.nil?
        language_range = LANGUAGE_TAG_PATTERN.match(language_string)
        raise Error if language_range.nil?
        Language.new(
          language_range[:primary_tag],
          language_range[:subtag],
          q: parse_q(q_string)
        )
      end
    end
  end
end
