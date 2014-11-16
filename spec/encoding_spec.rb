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

    describe "#accept?" do
      it "accepted if the encoding is the same" do
        a = subject.new('gzip')
        a.accept?('gzip').must_equal true
        b = subject.new('gzip', q: 0.001)
        b.accept?('gzip').must_equal true
      end

      it "accepted if the encoding is *" do
        a = subject.new('*')
        a.accept?('gzip').must_equal true
        b = subject.new('*', q: 0.1)
        b.accept?('gzip').must_equal true
      end

      it "not accepted if the encoding doesn't match" do
        a = subject.new('gzip')
        a.accept?('compress').must_equal false
        b = subject.new('gzip', q: 0.4)
        b.accept?('compress').must_equal false
      end

      it "not accepted if q is 0" do
        a = subject.new('gzip', q: 0)
        a.accept?('gzip').must_equal false
        b = subject.new('*', q: 0)
        b.accept?('gzip').must_equal false
      end

      # TODO: test *
      # it "not accepted if..." do
      #   a = subject.new('gzip')
      #   a.accept?('*').must_equal true
      # end
    end

    describe "#reject?" do
      describe "given q is 0" do
        it "rejected if the encoding is the same" do
          a = subject.new('gzip', q: 0)
          a.reject?('gzip').must_equal true
        end

        it "rejected if the encoding is *" do
          a = subject.new('*', q: 0)
          a.reject?('gzip').must_equal true
        end

        it "not rejected if the encoding doesn't match" do
          a = subject.new('gzip', q: 0)
          a.reject?('compress').must_equal false
        end

        # TODO: test *
        # it "not rejected if..." do
        #   a = subject.new('gzip', q: 0)
        #   a.reject?('*').must_equal true
        # end
      end

      it "not rejected if q > 0" do
        a = subject.new('gzip', q: 0.001)
        a.reject?('gzip').must_equal false
        b = subject.new('*', q: 0.9)
        b.reject?('gzip').must_equal false
      end
    end
  end
end
