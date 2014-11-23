require "accept_headers/acceptable"

module AcceptHeaders
  class Encoding
    include Comparable
    include Acceptable

    attr_reader :encoding

    ENCODING_PATTERN = /^\s*(?<encoding>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*$/

    def initialize(encoding = '*', q: 1.0)
      self.encoding = encoding
      self.q = q
    end

    def <=>(other)
      q <=> other.q
    end

    def encoding=(value)
      @encoding = value.strip.downcase
    end

    def to_h
      {
        encoding: encoding,
        q: q
      }
    end

    def to_s
      qvalue = (q == 0 || q == 1) ? q.to_i : q
      "#{encoding};q=#{qvalue}"
    end

    def match(encoding_string)
      match_data = ENCODING_PATTERN.match(encoding_string)
      if !match_data
        false
      elsif encoding == match_data[:encoding]
        true
      elsif match_data[:encoding] == 'identity'
        true
      elsif encoding == '*'
        true
      else
        false
      end
    end

    def self.parse(header)
      return nil if header.nil?
      header.strip!
      encoding_string, q_string = header.split(';', 2)
      raise Error if encoding_string.nil?
      encoding = ENCODING_PATTERN.match(encoding_string)
      raise Error if encoding.nil?
      Encoding.new(encoding[:encoding], q: parse_q(q_string))
    end
  end
end
