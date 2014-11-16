require_relative "spec_helper"

module AcceptHeaders
  describe MediaType do
    subject do
      AcceptHeaders::MediaType
    end

    it "defaults type to *" do
      subject.new.type.must_equal '*'
    end

    it "defaults subtype to *" do
      subject.new('text').subtype.must_equal '*'
    end

    it "strips and downcases the type" do
      subject.new("\t\nTEXt\s\r", '*').type.must_equal "text"
    end

    it "strips and downcases the subtype" do
      subject.new("text", "\s\npLAIn\r\t").subtype.must_equal "plain"
    end

    it "sets subtype to * if value passed in is nil and type is *" do
      subject.new('*', nil).subtype.must_equal '*'
    end

    it "strips the keys and values in the params hash" do
      subject.new('*', '*', params: { "\s\nLEVEL\r\t" => "\t\nX\s\n"}).params['LEVEL'].must_equal 'X'
    end

    it "optionally supports a q argument" do
      subject.new('text', 'html', q: 0.8).q.must_equal 0.8
    end

    it "optionally supports a params argument" do
      subject.new('text', 'html', params: { 'level' => '1' }).params['level'].must_equal '1'
    end

    it "compares on q value all other values remaining equal" do
      subject.new(q: 0.514).must_be :>, subject.new(q: 0.1)
      subject.new(q: 0).must_be :<, subject.new(q: 1)
      subject.new(q: 0.9).must_equal subject.new(q: 0.9)
    end

    it "compares on subtype then type all other values remaining equal" do
      subject.new('text', 'html').must_be :>, subject.new('text', '*')
      subject.new('*', '*').must_be :<, subject.new('text', '*')
    end

    it "raises an InvalidQError if q can't be converted to a float" do
      e = -> do
        subject.new('text', 'html', q: 'a')
      end.must_raise MediaType::InvalidQError

      e.message.must_equal 'invalid value for Float(): "a"'

      subject.new('text', 'html', q: '1')
    end

    it "raises an InvalidQError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('text', 'html', q: q)
        end.must_raise MediaType::InvalidQError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('text', 'html', q: 1)
      subject.new('text', 'html', q: 0)
    end

    it "raises an InvalidQError if q has more than a precision of 3" do
      e = -> do
        subject.new('text', 'html', q: 0.1234)
      end.must_raise MediaType::InvalidQError

      e.message.must_equal "q must be at most 3 decimal places"

      subject.new('text', 'html', q: 0.123)
    end

    it "converts to hash" do
      subject.new('text', 'html').to_h.must_equal({
        type: 'text',
        subtype: 'html',
        q: 1.0,
        params: {}
      })
    end

    it "converts to string" do
      s = subject.new('text', 'html', q: 0.9, params: { 'level' => '1' }).to_s
      s.must_equal "text/html;q=0.9;level=1"
    end

    it "outputs the media range" do
      subject.new('text', 'html', params: { 'level' => '1' }).media_range.must_equal "text/html"
    end

    describe "#accept?" do
      it "accepted if the type and subtype are the same" do
        a = subject.new('text', 'html')
        a.accept?('text/html').must_equal true
        b = subject.new('text', 'html', q: 0.001)
        b.accept?('text/html').must_equal true
      end

      it "accepted if the type is the same and the other subtype is *" do
        a = subject.new('text', '*')
        a.accept?('text/html').must_equal true
        b = subject.new('text', '*', q: 0.9)
        b.accept?('text/html').must_equal true
      end

      it "accepted if the type and subtype are *" do
        a = subject.new('*')
        a.accept?('text/html').must_equal true
        b = subject.new('*', q: 0.1)
        b.accept?('text/html').must_equal true
      end

      it "not accepted if the type and subtype don't match" do
        a = subject.new('text', 'html')
        a.accept?('application/json').must_equal false
        b = subject.new('text', 'html', q: 0.2)
        b.accept?('application/json').must_equal false
      end

      it "not accepted if the type doesn't match" do
        a = subject.new('text', 'plain')
        a.accept?('application/plain').must_equal false
        b = subject.new('text', 'plain', q: 0.4)
        b.accept?('application/json').must_equal false
      end

      it "not accepted if the subtype doesn't match" do
        a = subject.new('text', 'html')
        a.accept?('text/plain').must_equal false
        b = subject.new('text', 'html', q: 0.6)
        b.accept?('text/plain').must_equal false
      end

      it "not accepted if q is 0" do
        a = subject.new('text', 'html', q: 0)
        a.accept?('text/html').must_equal false
        a.accept?('text/plain').must_equal false
        a.accept?('application/plain').must_equal false
        b = subject.new('text', '*', q: 0)
        b.accept?('text/html').must_equal false
        c = subject.new('*', q: 0)
        c.accept?('text/html').must_equal false
      end

      # TODO: test *
      it "not accepted if..." do
        a = subject.new('text', 'plain')
        a.accept?('*').must_equal false
      end
    end

    describe "#reject?" do
      describe "given q is 0" do
        it "rejected if the type and subtype are the same" do
          a = subject.new('text', 'html', q: 0)
          a.reject?('text/html').must_equal true
        end

        it "rejected if the type is the same and the other subtype is *" do
          a = subject.new('text', '*', q: 0)
          a.reject?('text/html').must_equal true
        end

        it "rejected if the type and subtype are *" do
          a = subject.new('*', q: 0)
          a.reject?('text/html').must_equal true
        end

        it "not rejected if the type and subtype don't match" do
          a = subject.new('text', 'html', q: 0)
          a.reject?('application/json').must_equal false
        end

        it "not rejected if the type doesn't match" do
          a = subject.new('text', 'plain', q: 0)
          a.reject?('application/plain').must_equal false
        end

        it "not rejected if the subtype doesn't match" do
          a = subject.new('text', 'html', q: 0)
          a.reject?('text/plain').must_equal false
        end

        # TODO: test *
        it "not rejected if..." do
          a = subject.new('text', 'plain', q: 0)
          a.reject?('*').must_equal false
        end
      end

      it "not rejected if q > 0" do
        a = subject.new('text', 'html', q: 0.001)
        a.reject?('text/html').must_equal false
        a.reject?('text/plain').must_equal false
        a.reject?('application/plain').must_equal false
        b = subject.new('text', '*', q: 0.9)
        b.reject?('text/html').must_equal false
        c = subject.new('*', q: 1)
        c.reject?('text/html').must_equal false
      end
    end
  end
end
