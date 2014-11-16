require "accept_headers/language"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Language
    class Negotiator
      include Negotiatable

      private
      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept-Language:\s*/, '')
        header.strip!
        return [Language.new] if header.empty?
        languages = []
        header.split(',').each do |entry|
          language_arr = entry.split(';', 2)
          next if language_arr[0].nil?
          language_range = Language::LANGUAGE_TAG_PATTERN.match(language_arr[0])
          next if language_range.nil?
          begin
            languages << Language.new(
              language_range[:primary_tag],
              language_range[:subtag],
              q: parse_q(language_arr[1])
            )
          rescue Error
            next
          end
        end
        languages.sort! { |x,y| y <=> x }
      end
    end
  end
end
