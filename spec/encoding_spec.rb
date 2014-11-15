require_relative "spec_helper"

module AcceptHeaders
  describe Encoding do
    subject do
      AcceptHeaders::Encoding
    end

    it "defaults encoding to *" do
      subject.new.encoding.must_equal '*'
    end

    it "strips and downcases the encoding" do
      subject.new("\t\nGZIP\s\r").encoding.must_equal "gzip"
    end

    it "optionally supports a q argument" do
      subject.new('gzip', q: 0.8).q.must_equal 0.8
    end

    it "compares on q value all other values remaining equal" do
      subject.new(q: 0.514).must_be :>, subject.new(q: 0.1)
      subject.new(q: 0).must_be :<, subject.new(q: 1)
      subject.new(q: 0.9).must_equal subject.new(q: 0.9)
    end

    it "raises an InvalidQError if q can't be converted to a float" do
      e = -> do
        subject.new('gzip', q: 'a')
      end.must_raise Encoding::InvalidQError

      e.message.must_equal 'invalid value for Float(): "a"'

      subject.new('gzip', q: '1')
    end

    it "raises an InvalidQError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('gzip', q: q)
        end.must_raise Encoding::InvalidQError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('gzip', q: 1)
      subject.new('compress', q: 0)
    end

    it "raises an InvalidQError if q has more than a precision of 3" do
      e = -> do
        subject.new('gzip', q: 0.1234)
      end.must_raise Encoding::InvalidQError

      e.message.must_equal "q must be at most 3 decimal places"

      subject.new('gzip', q: 0.123)
    end

    it "converts to hash" do
      subject.new('gzip').to_h.must_equal({
        encoding: 'gzip',
        q: 1.0
      })
    end

    it "converts to string" do
      s = subject.new('gzip', q: 0.9).to_s
      s.must_equal "gzip;q=0.9"
    end
  end
end
