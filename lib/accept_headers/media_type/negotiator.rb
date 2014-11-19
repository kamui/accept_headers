require "accept_headers/media_type"
require "accept_headers/negotiatable"

module AcceptHeaders
  class MediaType
    class Negotiator
      include Negotiatable

      PARAM_PATTERN = /(?<attribute>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*\=\s*(?:\"(?<value>[^"]*)\"|\'(?<value>[^']*)\'|(?<value>[\w!#$%^&*\-\+{}\\|\'.`~]*))/

      private
      def parse(original_header)
        header = original_header.dup
        header.sub!(/\AAccept:\s*/, '')
        header.strip!
        return [MediaType.new] if header.empty?
        media_types = []
        header.split(',').each do |entry|
          accept_media_range, accept_params = entry.split(';', 2)
          next if accept_media_range.nil?
          media_range = MediaType::MEDIA_TYPE_PATTERN.match(accept_media_range)
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
        return {} if !params_string || params_string.empty?
        if params_string.match(/['"]/)
          params = params_string.scan(PARAM_PATTERN).map(&:compact).to_h
        else
          params = {}
          params_string.split(';').each do |part|
            param = PARAM_PATTERN.match(part)
            params[param[:attribute]] = param[:value] if param
          end
        end
        params.delete('q')
        params
      end
    end
  end
end
