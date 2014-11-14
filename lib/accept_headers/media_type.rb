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

    MEDIA_TYPE_PATTERN = /^\s*(?<type>[\w!#$%^&*\-\+{}\\|'.`~]+)(?:\s*\/\s*(?<subtype>[\w!#$%^&*\-\+{}\\|'.`~]+))?\s*$/
    PARAM_PATTERN = /(?<attribute>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*\=\s*(?:\"(?<value>[^"]*)\"|\'(?<value>[^']*)\'|(?<value>[\w!#$%^&*\-\+{}\\|\'.`~]*))/

    def self.parse(original_accept)
      accept = original_accept.dup
      accept.sub!(/\AAccept:\s*/, '')
      accept.strip!
      return [MediaType.new] if accept.empty?
      media_types = []
      accept.split(',').each do |entry|
        accept_media_range, accept_params = entry.split(';', 2)
        media_range = MEDIA_TYPE_PATTERN.match(accept_media_range)
        raise ParseError.new("Unable to parse type and subtype") unless media_range
        media_type = MediaType.new(media_range[:type], media_range[:subtype])
        params = parse_params(accept_params)
        if params['q']
          media_type.q = params['q']
          params.delete('q')
        end
        media_type.params = params
        media_types << media_type
      end
      media_types.sort! { |x,y| y <=> x }
    end

    private

    def self.parse_params(params_string)
      return {} if !params_string || params_string.empty?
      params = {}
      params_string.split(';').each do |part|
        param = PARAM_PATTERN.match(part)
        params[param[:attribute]] = param[:value] if param
      end
      params
    end
  end
end
