require "accept_headers/media_type"
require "accept_headers/negotiatable"

module AcceptHeaders
  class MediaType
    class Negotiator
      include Negotiatable

      PARAMS_PATTERN = /(?<attribute>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*\=\s*(?:\"(?<value>[^"]*)\"|\'(?<value>[^']*)\'|(?<value>[\w!#$%^&*\-\+{}\\|\'.`~]*))/

      private
      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept:\s*/, '')
        header.strip!
        return [MediaType.new] if header.empty?
        media_types = []
        header.split(',').each do |entry|
          accept_media_range, accept_extensions = entry.split(';', 2)
          next if accept_media_range.nil?
          media_range = MediaType::MEDIA_TYPE_PATTERN.match(accept_media_range)
          next if media_range.nil?
          begin
            media_types << MediaType.new(
              media_range[:type],
              media_range[:subtype],
              q: parse_q(accept_extensions),
              extensions: parse_extensions(accept_extensions)
            )
          rescue Error
            next
          end
        end
        media_types.sort! { |x,y| y <=> x }
      end

      def parse_extensions(extensions_string)
        return {} if !extensions_string || extensions_string.empty?
        if extensions_string.match(/['"]/)
          extensions = extensions_string.scan(PARAMS_PATTERN).map(&:compact).to_h
        else
          extensions = {}
          extensions_string.split(';').each do |part|
            param = PARAMS_PATTERN.match(part)
            extensions[param[:attribute]] = param[:value] if param
          end
        end
        extensions.delete('q')
        extensions
      end
    end
  end
end
