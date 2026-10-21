require "accept_headers/acceptable"

module AcceptHeaders
  class MediaType
    include Comparable
    include Acceptable

    attr_reader :type, :subtype, :extensions

    def initialize(type = '*', subtype = '*', q: 1.0, extensions: {})
      self.type = type
      self.subtype = subtype
      self.q = q
      self.extensions = extensions
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
      elsif extensions.size < other.extensions.size
        -1
      elsif extensions.size > other.extensions.size
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

    def extensions=(hash)
      @extensions = {}
      hash.each do |k,v|
        @extensions[k.strip.downcase] = v
      end
      @extensions
    end

    def to_h
      {
        type: type,
        subtype: subtype,
        q: q,
        extensions: extensions
      }
    end

    def to_s
      qvalue = (q == 0 || q == 1) ? q.to_i : q
      content_type.concat(";q=#{qvalue}")
    end

    def content_type
      string = media_range
      if extensions.size > 0
        extensions.each do |key, value|
          value = value.to_s
          unless /\A[!#$%&'*+\-.^_`|~0-9A-Za-z]+\z/.match(value.b)
            value = '"' + value.b.gsub(/["\\]/) { |character| "\\#{character}" }.force_encoding(value.encoding) + '"'
          end
          string.concat(";#{key}=#{value}")
        end
      end
      string
    end

    def media_range
      "#{type}/#{subtype}"
    end

    def specificity
      [type == '*' ? 0 : 1, subtype == '*' ? 0 : 1, extensions.size]
    end

    def match(media_range_string)
      return false if media_range_string.nil? || media_range_string.strip.empty?
      candidates = Negotiator.new(media_range_string).list
      return false unless candidates.size == 1
      candidate = candidates.first
      return false unless (type == '*' || type == candidate.type) &&
        (subtype == '*' || subtype == candidate.subtype)

      extensions.all? do |name, value|
        supported_value = candidate.extensions[name]
        if value.is_a?(String) && supported_value.is_a?(String)
          value = value.b
          supported_value = supported_value.b
        end
        if name == 'charset'
          supported_value && value.casecmp?(supported_value)
        else
          value == supported_value
        end
      end
    end
  end
end
