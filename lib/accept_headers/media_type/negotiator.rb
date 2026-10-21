require "accept_headers/media_type"
require "accept_headers/negotiatable"

module AcceptHeaders
  class MediaType
    class Negotiator
      include Negotiatable

      MEDIA_TYPE_PATTERN = /\A[ \t]*(?<type>[!#$%&'*+\-.^_`|~0-9A-Za-z]+)(?:\/(?<subtype>[!#$%&'*+\-.^_`|~0-9A-Za-z]+))?[ \t]*\z/
      PARAMS_PATTERN = /\A\s*(?<attribute>[!#$%&'*+\-.^_`|~0-9A-Za-z]+)\s*=\s*(?<value>[!#$%&'*+\-.^_`|~0-9A-Za-z]+|"(?:[\t !#-\[\]-~\x80-\xFF]|\\[\t -~\x80-\xFF])*")\s*\z/n
      HEADER_PREFIX = 'Accept:'

      def negotiate(supported)
        support, = super(supported)
        return nil if support.nil?
        parse(support).first
      end

      private
      def valid_supported_value?(value)
        media_range_string, *parameters = split_quoted(value.b, ';')
        media_range = MEDIA_TYPE_PATTERN.match(media_range_string)
        return false unless media_range && media_range[:subtype]
        return false if media_range[:type] == '*' || media_range[:subtype] == '*'
        parameters.all? do |parameter|
          next true if parameter.strip.empty?
          match = PARAMS_PATTERN.match(parameter)
          match && match[:attribute].downcase != 'q'
        end
      rescue ParseError
        false
      end

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
        raise Error if media_range[:subtype].nil? && media_range[:type] != '*'
        raise Error if media_range[:type] == '*' && ![nil, '*'].include?(media_range[:subtype])
        MediaType.new(
          media_range[:type],
          media_range[:subtype],
          q: parse_q(accept_extensions),
          extensions: parse_extensions(accept_extensions)
        )
      end

      def parse_extensions(extensions_string)
        return {} if !extensions_string || extensions_string.empty?
        extensions = {}
        split_quoted(extensions_string, ';').each do |part|
          next if part.strip.empty?
          name = part.split('=', 2).first.strip.downcase
          next if name == 'q'
          param = PARAMS_PATTERN.match(part.b)
          raise ParseError unless param
          value = param[:value].force_encoding(part.encoding)
          if value.start_with?('"')
            value = value.b[1...-1].gsub(/\\(.)/m, '\\1').force_encoding(part.encoding)
          end
          extensions[param[:attribute].downcase] = value
        end
        extensions
      end
    end
  end
end
