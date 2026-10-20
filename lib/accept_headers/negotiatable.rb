module AcceptHeaders
  module Negotiatable
    class Error < StandardError; end
    class ParseError < Error; end

    attr_reader :list

    Q_PATTERN = /\A[ \t]*q[ \t]*=[ \t]*(?<q>.*?)[ \t]*\z/im
    QVALUE_PATTERN = /\A(?:0(?:\.[0-9]{0,3})?|1(?:\.0{0,3})?)\z/

    def initialize(header)
      @list = parse(header)
    end

    def negotiate(supported)
      candidates = [*supported].each_with_index.map do |support, support_index|
        matches = list.each_with_index.select { |part, _| part.match(support) }
        part, header_index = matches.max_by do |match, _|
          [match.specificity, match.q.zero? ? 1 : 0, match.q]
        end
        next if part.nil? || part.q.zero?
        [support, part, header_index, support_index]
      end.compact
      best = candidates.max_by do |_, part, header_index, support_index|
        [part.q, part.specificity, -header_index, -support_index]
      end
      best && best.first(2)
    end

    def accept?(other)
      negotiate(other) ? true : false
    end

    def to_s
      list.join(',')
    end

    private
    def no_header
      raise NotImplementedError.new("#no_header is not implemented")
    end

    def parse_item(entry)
      raise NotImplementedError.new("#parse_item(entry) is not implemented")
    end

    def parse(header, &block)
      return no_header unless header
      header = header.dup
      header.sub!(/\A#{self.class::HEADER_PREFIX}\s*/, '')
      header.strip!
      return [] if header.empty?
      list = []
      header.split(',').each do |entry|
        begin
          item = parse_item(entry)
          next if item.nil?
          list << item
        rescue Error
          next
        end
      end
      list.sort! { |x,y| y <=> x }
    end

    def split_quoted(value, delimiter)
      parts = []
      part = +""
      quoted = false
      escaped = false
      value.each_char do |character|
        if escaped
          escaped = false
        elsif quoted && character == "\\"
          escaped = true
        elsif character == '"'
          quoted = !quoted
        elsif !quoted && character == delimiter
          parts << part
          part = +""
          next
        end
        part << character
      end
      raise ParseError if quoted || escaped
      parts << part
    end

    def parse_q(header)
      return 1 unless header
      split_quoted(header, ';').each do |parameter|
        q_match = Q_PATTERN.match(parameter)
        next unless q_match
        value = q_match[:q]
        return QVALUE_PATTERN.match(value) ? value.to_f : 0.001
      end
      1
    end
  end
end
