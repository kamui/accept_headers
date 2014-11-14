require "accept_headers/acceptable"

module AcceptHeaders
  class MediaType
    include Comparable
    include Acceptable

    attr_reader :type, :subtype, :params

    def initialize(type = '*', subtype = '*', q: 1.0, params: {})
      self.type = type
      self.subtype = subtype
      self.q = q
      self.params = params
    end

    def <=>(other)
      if q < other.q
        -1
      elsif q > other.q
        1
      elsif (type == '*' && other.type != '*') || (subtype == '*' && other.subtype != '*')
        -1
      elsif (type != '*' && other.type == '*') || (subtype != '*' && other.subtype == '*')
        1
      elsif params.size < other.params.size
        -1
      elsif params.size > other.params.size
        1
      else
        0
      end
    end

    def type=(value)
      @type = value.strip.downcase
    end

    def subtype=(value)
      @subtype = if value.nil? && type == '*'
        '*'
      else
        value.strip.downcase
      end
    end

    def params=(hash)
      @params = {}
      hash.each do |k,v|
        @params[k.strip] = v.strip
      end
      @params
    end

    def to_h
      {
        type: type,
        subtype: subtype,
        q: q,
        params: params
      }
    end

    def to_s
      qvalue = (q == 0 || q == 1) ? q.to_i : q
      string = "#{type}/#{subtype};q=#{qvalue}"
      if params.size > 0
        params.each { |k, v| string.concat(";#{k}=#{v}") }
      end
      string
    end

    def match(other)
      if type == other.type && subtype == other.subtype
        true
      elsif type == other.type && subtype == '*'
        true
      elsif other.type == '*' && other.subtype == '*'
        true
      else
        false
      end
    end

    MEDIA_TYPE_PATTERN = /^\s*(?<type>[\w!#$%^&*\-\+{}\\|'.`~]+)(?:\s*\/\s*(?<subtype>[\w!#$%^&*\-\+{}\\|'.`~]+))?\s*$/
    PARAM_PATTERN = /(?<attribute>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*\=\s*(?:\"(?<value>[^"]*)\"|\'(?<value>[^']*)\'|(?<value>[\w!#$%^&*\-\+{}\\|\'.`~]*))/

    def self.parse(original_header)
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

    private

    def self.parse_params(params_string)
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
