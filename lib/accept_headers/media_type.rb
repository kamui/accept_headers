require "accept_headers/acceptable"

module AcceptHeaders
  class MediaType
    include Comparable
    include Acceptable

    class InvalidTypeSubtypeError < Error; end

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

    def self.parse(accept)
      media_types = accept.strip.split(',')
      return [MediaType.new] if media_types.empty?
      media_types.map do |entry|
        parts = entry.split(';')
        type_subtype = parts.shift.split('/')
        media_type = MediaType.new(type_subtype[0], type_subtype[1])
        if type_subtype.size > 2
          raise InvalidTypeSubtypeError.new("Unable to parse type and subtype")
        end
        params = {}
        parts.each do |p|
          key_value = p.split('=', 2)
          next if key_value.size != 2
          key, value = key_value
          if key.strip == 'q'
            media_type.q = value
            next
          end
          params[key] = value
        end
        media_type.params = params
        media_type
      end.sort! { |x,y| y <=> x }
    end
  end
end
