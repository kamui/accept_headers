require "accept_headers/media_type"
require "accept_headers/negotiatable"

module AcceptHeaders
  class MediaType
    class Negotiator
      include Negotiatable

      private
      MEDIA_TYPE_PATTERN = /^\s*(?<type>[\w!#$%^&*\-\+{}\\|'.`~]+)(?:\s*\/\s*(?<subtype>[\w!#$%^&*\-\+{}\\|'.`~]+))?\s*$/
      PARAM_PATTERN = /(?<attribute>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*\=\s*(?:\"(?<value>[^"]*)\"|\'(?<value>[^']*)\'|(?<value>[\w!#$%^&*\-\+{}\\|\'.`~]*))/

      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept:\s*/, '')
        header.strip!
        return [MediaType.new] if header.empty?
        media_types = []
        header.split(',').each do |entry|
          accept_media_range, accept_params = entry.split(';', 2)
          next if accept_media_range.nil?
          media_range = MEDIA_TYPE_PATTERN.match(accept_media_range)
          next if media_range.nil?
          begin
            media_types << MediaType.new(
              media_range[:type],
              media_range[:subtype],
              q: parse_q(accept_params),
              params: parse_params(accept_params)
            )
          rescue Error
            next
          end
        end
        media_types.sort! { |x,y| y <=> x }
      end

      def parse_params(params_string)
        params = {}
        return params if !params_string || params_string.empty?
        params_string.split(';').each do |part|
          param = PARAM_PATTERN.match(part)
          params[param[:attribute]] = param[:value] if param
        end
        params.delete('q')
        params
      end
    end
  end
end
