module AcceptHeaders
  module Negotiatable
    class Error < StandardError; end
    class ParseError < Error; end

    Q_PATTERN = /(?:\A|;)\s*(?<exists>qs*\=)\s*(?:(?<q>0\.\d{1,3}|[01])|(?:[^;]*))\s*(?:\z|;)/

    attr_reader :list

    def initialize(header)
      @list = parse(header)
    end

    def negotiate(supported)
      return nil if @list.empty?
      supported = [*supported]
      rejects, acceptable = @list.partition { |m| m.q == 0.0 }
      rejects.each do |reject|
        supported.each do |support|
          if reject.reject?(support)
            return nil
          end
        end
      end
      acceptable.sort { |x,y| y <=> x }.each do |accepted|
        supported.each do |support|
          if accepted.accept?(support)
            return accepted
          end
        end
      end
      nil
    end

    def accept?(other)
      negotiate(other) ? true : false
    end

    private
    def parse(header)
      raise NotImplementedError.new("#parse(header) is not implemented")
    end

    def parse_q(header)
      q = 1
      return q unless header
      q_match = Q_PATTERN.match(header)
      if q_match && q_match[:exists]
        if q_match[:q]
          q = q_match[:q]
        else
          q = 0.001
        end
      end
      q
    end
  end
end
