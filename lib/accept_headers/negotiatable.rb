module AcceptHeaders
  module Negotiatable
    class Error < StandardError; end
    class ParseError < Error; end

    attr_reader :list

    def initialize(header)
      @list = parse(header)
    end

    def negotiate(supported)
      return nil if list.empty?
      supported = [*supported]
      # TODO: Maybe q=0 should be first by default when sorting
      rejects, acceptable = list.partition { |m| m.q == 0.0 }
      (rejects + acceptable).each do |part|
        supported.each do |support|
          if part.match(support)
            if part.q == 0.0
              next
            else
              return [support, part]
            end
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
  end
end
