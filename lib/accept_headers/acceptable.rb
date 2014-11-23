module AcceptHeaders
  module Acceptable
    class Error < StandardError; end
    class InvalidQError < Error; end

    attr_reader :q

    Q_PATTERN = /(?:\A|;)\s*(?<exists>qs*\=)\s*(?:(?<q>0\.\d{1,3}|[01])|(?:[^;]*))\s*(?:\z|;)/

    def self.included(base)
      base.extend ClassMethods
    end

    def reject?(other)
      if q != 0.0
        false
      else
        match(other)
      end
    end

    def accept?(other)
      if q == 0.0
        false
      else
        match(other)
      end
    end

    def q=(value)
      begin
        q_float = Float(value)
      rescue ArgumentError => e
        raise InvalidQError.new(e.message)
      end
      if !q_float.between?(0.0, 1.0)
        raise InvalidQError.new("q must be between 0 and 1")
      end
      if q_float.to_s.match(/^\d\.(\d+)$/) && $1 && $1.size > 3
        raise InvalidQError.new("q must be at most 3 decimal places")
      end
      @q = q_float
    end

    def match(other)
      raise NotImplementedError.new("#match is not implemented")
    end

    module ClassMethods
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
