module AcceptHeaders
  module Acceptable
    class Error < StandardError; end
    class OutOfRangeError < Error; end
    class InvalidPrecisionError < Error; end
    class InvalidQError < Error; end
    class ParseError < Error; end

    attr_reader :q

    TOKEN_PATTERN = /^\s*(?<token>[\w!#$%^&*\-\+{}\\|'.`~]+)\s*$/

    def self.included(base)
      base.extend ClassMethods
    end

    def match(other)
      raise NotImplementedError.new("#match is not implemented")
    end

    def q=(value)
      begin
        q_float = Float(value)
      rescue ArgumentError => e
        raise InvalidQError.new(e.message)
      end
      if !q_float.between?(0.0, 1.0)
        raise OutOfRangeError.new("q must be between 0 and 1")
      end
      if q_float.to_s.match(/^\d\.(\d+)$/) && $1 && $1.size > 3
        raise InvalidPrecisionError.new("q must be at most 3 decimal places")
      end
      @q = q_float
    end

    module ClassMethods
      Q_PATTERN = /(?:\A|;)\s*(?<exists>qs*\=)\s*(?:(?<q>0\.\d{1,3}|[01])|(?:[^;]*))\s*(?:\z|;)/

      def negotiate(available, supported)
        return nil if available.empty?
        rejects, acceptable = available.partition { |m| m.q == 0.0 }
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
      end

      private
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
end
