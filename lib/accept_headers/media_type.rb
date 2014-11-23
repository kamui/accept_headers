require "accept_headers/acceptable"

module AcceptHeaders
  class MediaType
    include Comparable
    include Acceptable

    attr_reader :type, :subtype, :extensions

    MEDIA_TYPE_PATTERN = /^\s*(?<type>[\w!#$%^&*\-\+{}\\|'.`~]+)(?:\s*\/\s*(?<subtype>[\w!#$%^&*\-\+{}\\|'.`~]+))?\s*$/
    PARAMS_PATTERN = /(?<attribute>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*\=\s*(?:\"(?<value>[^"]*)\"|\'(?<value>[^']*)\'|(?<value>[\w!#$%^&*\-\+{}\\|\'.`~]*))/

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
        @extensions[k.strip] = v
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
      string = "#{media_range};q=#{qvalue}"
      if extensions.size > 0
        extensions.each { |k, v| string.concat(";#{k}=#{v}") }
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

    def self.parse(header)
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

    private
    def self.parse_extensions(extensions_string)
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
