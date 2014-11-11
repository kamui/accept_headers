module AcceptHeaders
  module Acceptable
    class Error < StandardError; end
    class OutOfRangeError < Error; end
    class InvalidPrecisionError < Error; end
    class InvalidQError < Error; end

    attr_reader :q

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
  end
end
