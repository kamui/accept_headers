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

    it "raises an InvalidQError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('iso-8859-1', q: q)
        end.must_raise Charset::InvalidQError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('iso-8859-1', q: 1)
      subject.new('unicode-1-1', q: 0)
    end

    it "raises an InvalidQError if q has more than a precision of 3" do
      e = -> do
        subject.new('iso-8859-1', q: 0.1234)
      end.must_raise Charset::InvalidQError

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
  end
end
