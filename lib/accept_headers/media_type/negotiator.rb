require "accept_headers/media_type"
require "accept_headers/negotiatable"

module AcceptHeaders
  class MediaType
    class Negotiator
      include Negotiatable

      def negotiate(supported)
        support, match = super(supported)
        return nil if support.nil? && match.nil?
        begin
          media_type = MediaType.parse(support)
          media_type.extensions = match.extensions
          return media_type
        rescue MediaType::Error
          return nil
        end
      end

      private
      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept:\s*/, '')
        header.strip!
        return [MediaType.new] if header.empty?
        media_types = []
        header.split(',').each do |entry|
          begin
            media_type = MediaType.parse(entry)
            next if media_type.nil?
            media_types << media_type
          rescue MediaType::Error
            next
          end
        end
        media_types.sort! { |x,y| y <=> x }
      end
    end
  end
end
