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

    it "raises an OutOfRangeError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('gzip', q: q)
        end.must_raise Encoding::OutOfRangeError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('gzip', q: 1)
      subject.new('compress', q: 0)
    end

    it "raises an InvalidPrecisionError if q has more than a precision of 3" do
      e = -> do
        subject.new('gzip', q: 0.1234)
      end.must_raise Encoding::InvalidPrecisionError

      e.message.must_equal "q must be at most 3 decimal places"

      subject.new('gzip', q: 0.123)
    end

    it "converts to hash" do
      subject.new('gzip').to_h.must_equal({
        encoding: 'gzip',
        q: 1.0
      })
    end

    it "convers to string" do
      s = subject.new('gzip', q: 0.9).to_s
      s.must_equal "gzip;q=0.9"
    end

    describe "parsing an accept header" do
      it "returns a sorted array of encodings" do
        subject.parse("*; q=0.2, compress").must_equal [
          Encoding.new('compress'),
          Encoding.new('*', q: 0.2)
        ]

        subject.parse("deflate; q=0.5, gzip, compress; q=0.8, identity").must_equal [
          Encoding.new('gzip'),
          Encoding.new('identity'),
          Encoding.new('compress', q: 0.8),
          Encoding.new('deflate', q: 0.5)
        ]
      end

      it "sets encoding to * when the accept-encoding header is empty" do
        subject.parse('').must_equal [
          Encoding.new('*')
        ]
      end

      it "defaults q to 1 if it's not explicitly specified" do
        subject.parse("gzip").must_equal [
          Encoding.new('gzip', q: 1.0)
        ]
      end

      it "strips whitespace from between encodings" do
        subject.parse("\tcompress\r,\ngzip\s").must_equal [
          Encoding.new('compress'),
          Encoding.new('gzip')
        ]
      end

      it "strips whitespace around q" do
        subject.parse("gzip;\tq\r=\n1, compress;q=0.8\n").must_equal [
          Encoding.new('gzip'),
          Encoding.new('compress', q: 0.8)
        ]
      end

      it "has a q value of 0.001 when parsed q is invalid" do
        subject.parse("gzip;q=x").must_equal [
          Encoding.new('gzip', q: 0.001)
        ]
      end

      it "skips invalid encodings" do
        subject.parse("gzip, @blah").must_equal [
          Encoding.new('gzip', q: 1.0)
        ]
      end
    end

    describe "negotiate supported encodings" do
      it "returns a best matching encoding" do
        available = [
          Encoding.new('gzip'),
          Encoding.new('identity'),
          Encoding.new('compress', q: 0.8),
          Encoding.new('deflate', q: 0.5)
        ]
        match = Encoding.new('identity')
        subject.negotiate(available, [match]).must_equal match
      end
    end
  end
end
