require "accept_headers/media_type"
require "accept_headers/negotiatable"

module AcceptHeaders
  class MediaType
    class Negotiator
      include Negotiatable

      MEDIA_TYPE_PATTERN = /^\s*(?<type>[\w!#$%^&*\-\+{}\\|'.`~]+)(?:\s*\/\s*(?<subtype>[\w!#$%^&*\-\+{}\\|'.`~]+))?\s*$/
      PARAMS_PATTERN = /(?<attribute>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*\=\s*(?:\"(?<value>[^"]*)\"|\'(?<value>[^']*)\'|(?<value>[\w!#$%^&*\-\+{}\\|\'.`~]*))/
      HEADER_PREFIX = 'Accept:'

      def negotiate(supported)
        support, match = super(supported)
        return nil if support.nil? && match.nil?
        begin
          media_type = parse(support).first
          media_type.extensions = match.extensions
          return media_type
        rescue MediaType::Error
          return nil
        end
      end

      private
      def no_header
        [MediaType.new]
      end

      def parse_item(header)
        return nil if header.nil?
        header.strip!
        accept_media_range, accept_extensions = header.split(';', 2)
        raise Error if accept_media_range.nil?
        media_range = MEDIA_TYPE_PATTERN.match(accept_media_range)
        raise Error if media_range.nil?
        MediaType.new(
          media_range[:type],
          media_range[:subtype],
          q: parse_q(accept_extensions),
          extensions: parse_extensions(accept_extensions)
        )
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
