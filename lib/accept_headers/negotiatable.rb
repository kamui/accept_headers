module AcceptHeaders
  module Negotiatable
    class Error < StandardError; end
    class ParseError < Error; end

    TOKEN_PATTERN = /^\s*(?<token>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*$/
    Q_PATTERN = /(?:\A|;)\s*(?<exists>qs*\=)\s*(?:(?<q>0\.\d{1,3}|[01])|(?:[^;]*))\s*(?:\z|;)/

    attr_reader :list

    def initialize(header)
      @list = parse(header)
    end

    def negotiate(supported_string)
      supported = parse(supported_string)
      return nil if @list.empty?
      rejects, acceptable = @list.partition { |m| m.q == 0.0 }
      rejects.each do |reject|
        supported.each do |support|
          if support.match(reject)
            return nil
          end
        end
      end
      acceptable.sort { |x,y| y <=> x }.each do |accepted|
        supported.each do |support|
          if support.match(accepted)
            return accepted
          end
        end
      end
      nil
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
