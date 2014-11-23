require "accept_headers/language"
require "accept_headers/negotiatable"

module AcceptHeaders
  class Language
    class Negotiator
      include Negotiatable

      def negotiate(supported)
        support, match = super(supported)
        return nil if support.nil? && match.nil?
        begin
          return Language.parse(support)
        rescue Language::Error
          return nil
        end
      end

      private
      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept-Language:\s*/, '')
        header.strip!
        return [Language.new] if header.empty?
        languages = []
        header.split(',').each do |entry|
          begin
            language = Language.parse(entry)
            next if language.nil?
            languages << language
          rescue Language::Error
            next
          end
        end
        languages.sort! { |x,y| y <=> x }
      end
    end
  end
end
