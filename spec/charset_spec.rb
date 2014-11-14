require_relative "spec_helper"

module AcceptHeaders
  describe Charset do
    subject do
      AcceptHeaders::Charset
    end

    it "defaults charset to *" do
      subject.new.charset.must_equal '*'
    end

    it "strips and downcases the charset" do
      subject.new("\t\nISO-8859-1\s\r").charset.must_equal "iso-8859-1"
    end

    it "optionally supports a q argument" do
      subject.new('iso-8859-1', q: 0.8).q.must_equal 0.8
    end

    it "compares on q value all other values remaining equal" do
      subject.new(q: 0.514).must_be :>, subject.new(q: 0.1)
      subject.new(q: 0).must_be :<, subject.new(q: 1)
      subject.new(q: 0.9).must_equal subject.new(q: 0.9)
    end

    it "raises an InvalidQError if q can't be converted to a float" do
      e = -> do
        subject.new('iso-8859-1', q: 'a')
      end.must_raise Charset::InvalidQError

      e.message.must_equal 'invalid value for Float(): "a"'

      subject.new('iso-8859-1', q: '1')
    end

    it "raises an OutOfRangeError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('iso-8859-1', q: q)
        end.must_raise Charset::OutOfRangeError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('iso-8859-1', q: 1)
      subject.new('unicode-1-1', q: 0)
    end

    it "raises an InvalidPrecisionError if q has more than a precision of 3" do
      e = -> do
        subject.new('iso-8859-1', q: 0.1234)
      end.must_raise Charset::InvalidPrecisionError

      e.message.must_equal "q must be at most 3 decimal places"

      subject.new('iso-8859-1', q: 0.123)
    end

    it "converts to hash" do
      subject.new('iso-8859-1').to_h.must_equal({
        charset: 'iso-8859-1',
        q: 1.0
      })
    end

    it "convers to string" do
      s = subject.new('iso-8859-1', q: 0.9).to_s
      s.must_equal "iso-8859-1;q=0.9"
    end

    describe "parsing an accept header" do
      it "returns a sorted array of charsets" do
        subject.parse("*; q=0.2, unicode-1-1").must_equal [
          Charset.new('unicode-1-1'),
          Charset.new('*', q: 0.2)
        ]

        subject.parse("us-ascii; q=0.5, iso-8859-1, utf-8; q=0.8, macintosh").must_equal [
          Charset.new('iso-8859-1'),
          Charset.new('macintosh'),
          Charset.new('utf-8', q: 0.8),
          Charset.new('us-ascii', q: 0.5)
        ]
      end

      it "sets charset to * when the accept-charset header is empty" do
        subject.parse('').must_equal [
          Charset.new('*')
        ]
      end

      it "defaults q to 1 if it's not explicitly specified" do
        subject.parse("iso-8859-1").must_equal [
          Charset.new('iso-8859-1', q: 1.0)
        ]
      end

      it "strips whitespace from between charsets" do
        subject.parse("\tunicode-1-1\r,\niso-8859-1\s").must_equal [
          Charset.new('unicode-1-1'),
          Charset.new('iso-8859-1')
        ]
      end

      it "strips whitespace around q" do
        subject.parse("iso-8859-1;\tq\r=\n1, unicode-1-1;q=0.8\n").must_equal [
          Charset.new('iso-8859-1'),
          Charset.new('unicode-1-1', q: 0.8)
        ]
      end

      it "has a q value of 0.001 when parsed q is invalid" do
        subject.parse("iso-8859-1;q=x").must_equal [
          Charset.new('iso-8859-1', q: 0.001)
        ]
      end

      it "skips invalid character sets" do
        subject.parse("iso-8859-1, @unicode-1-1").must_equal [
          Charset.new('iso-8859-1', q: 1)
        ]
      end
    end
  end
end
