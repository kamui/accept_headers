require "accept_headers/acceptable"

module AcceptHeaders
  class MediaType
    include Comparable
    include Acceptable

    attr_reader :type, :subtype, :params

    MEDIA_TYPE_PATTERN = /^\s*(?<type>[\w!#$%^&*\-\+{}\\|'.`~]+)(?:\s*\/\s*(?<subtype>[\w!#$%^&*\-\+{}\\|'.`~]+))?\s*$/

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
      string = "#{media_range};q=#{qvalue}"
      if params.size > 0
        params.each { |k, v| string.concat(";#{k}=#{v}") }
      end
      string
    end

    def media_range
      "#{type}/#{subtype}"
    end

    def match(media_range_string)
      match_data = MEDIA_TYPE_PATTERN.match(media_range_string)
      if !match_data
        false
      elsif type == match_data[:type] && subtype == match_data[:subtype]
        true
      elsif type == match_data[:type] && subtype == '*'
        true
      elsif type == '*' && subtype == '*'
        true
      else
        false
      end
    end
  end
end
