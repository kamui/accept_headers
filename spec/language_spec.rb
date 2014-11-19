require_relative "spec_helper"

describe AcceptHeaders::Language do
  subject do
    AcceptHeaders::Language
  end

  it "defaults primary tag to *" do
    subject.new.primary_tag.must_equal '*'
  end

  it "defaults subtag to *" do
    subject.new('en').subtag.must_equal '*'
  end

  it "strips and downcases the primary tag" do
    subject.new("\t\nEN\s\r", '*').primary_tag.must_equal "en"
  end

  it "strips and downcases the subtag" do
    subject.new("en", "\s\nUS\r\t").subtag.must_equal "us"
  end

  it "sets subtag to * if value passed in is nil and primary tag is *" do
    subject.new('*', nil).subtag.must_equal '*'
  end

  it "optionally supports a q argument" do
    subject.new('en', 'us', q: 0.8).q.must_equal 0.8
  end

  it "compares on q value all other values remaining equal" do
    subject.new(q: 0.514).must_be :>, subject.new(q: 0.1)
    subject.new(q: 0).must_be :<, subject.new(q: 1)
    subject.new(q: 0.9).must_equal subject.new(q: 0.9)
  end

  it "compares on subtag then primary tag all other values remaining equal" do
    subject.new('en', 'us').must_be :>, subject.new('en', '*')
    subject.new('*', '*').must_be :<, subject.new('en', '*')
  end

  it "raises an InvalidQError if q can't be converted to a float" do
    e = -> do
      subject.new('en', 'us', q: 'a')
    end.must_raise AcceptHeaders::Language::InvalidQError

    e.message.must_match INVALID_FLOAT_PATTERN

    subject.new('en', 'us', q: '1')
  end

  it "raises an InvalidQError unless q value is between 0 and 1" do
    [-1.0, -0.1, 1.1].each do |q|
      e = -> do
        subject.new('en', 'us', q: q)
      end.must_raise AcceptHeaders::Language::InvalidQError

      e.message.must_equal "q must be between 0 and 1"
    end

    subject.new('en', 'us', q: 1)
    subject.new('en', 'gb', q: 0)
  end

  it "raises an InvalidQError if q has more than a precision of 3" do
    e = -> do
      subject.new('en', 'us', q: 0.1234)
    end.must_raise AcceptHeaders::Language::InvalidQError

    e.message.must_equal "q must be at most 3 decimal places"

    subject.new('en', 'us', q: 0.123)
  end

  it "converts to hash" do
    subject.new('en', 'us').to_h.must_equal({
      primary_tag: 'en',
      subtag: 'us',
      q: 1.0
    })
  end

  it "converts to string" do
    s = subject.new('en', 'us', q: 0.9).to_s
    s.must_equal "en-us;q=0.9"
  end

  describe "#language_tag" do
    it "outputs the language tag" do
      subject.new('en', 'us', q: 0.9).language_tag.must_equal "en-us"
    end

    it "if primary tag is * and subtag is * or nil, outputs *" do
      subject.new('*', nil).language_tag.must_equal '*'
      subject.new('*', '*').language_tag.must_equal '*'
    end
  end

  describe "#accept?" do
    it "accepted if the primary_tag and subtag are the same" do
      a = subject.new('en', 'us')
      a.accept?('en-us').must_equal true
      b = subject.new('en', 'us', q: 0.001)
      b.accept?('en-us').must_equal true
    end

    it "accepted if the primary_tag is the same and the other subtag is *" do
      a = subject.new('en', '*')
      a.accept?('en-us').must_equal true
      b = subject.new('en', '*', q: 0.9)
      b.accept?('en-us').must_equal true
    end

    it "accepted if the primary_tag and subtag are *" do
      a = subject.new('*')
      a.accept?('en-us').must_equal true
      b = subject.new('*', q: 0.1)
      b.accept?('en-us').must_equal true
    end

    it "not accepted if the primary_tag and subtag don't match" do
      a = subject.new('en', 'us')
      a.accept?('en-gb').must_equal false
      b = subject.new('en', 'us', q: 0.2)
      b.accept?('en-gb').must_equal false
    end

    it "not accepted if the primary_tag doesn't match" do
      a = subject.new('en', 'us')
      a.accept?('zh-us').must_equal false
      b = subject.new('en', 'us', q: 0.4)
      b.accept?('zh-us').must_equal false
    end

    it "not accepted if the subtag doesn't match" do
      a = subject.new('en', 'us')
      a.accept?('en-gb').must_equal false
      b = subject.new('en', 'us', q: 0.6)
      b.accept?('en-gb').must_equal false
    end

    it "not accepted if q is 0" do
      a = subject.new('en', 'us', q: 0)
      a.accept?('en-us').must_equal false
      a.accept?('en-gb').must_equal false
      a.accept?('zh-us').must_equal false
      b = subject.new('en', '*', q: 0)
      b.accept?('en-us').must_equal false
      c = subject.new('*', q: 0)
      c.accept?('en-us').must_equal false
    end

    it "not accepted compared against nil" do
      a = subject.new('en', 'us')
      a.accept?(nil).must_equal false
    end

    # TODO: test *
    it "not accepted if..." do
      a = subject.new('en', 'us')
      a.accept?('*').must_equal false
    end
  end

  describe "#reject?" do
    describe "given q is 0" do
      it "rejected if the primary_tag and subtag are the same" do
        a = subject.new('en', 'us', q: 0)
        a.reject?('en-us').must_equal true
      end

      it "rejected if the primary_tag is the same and the other subtag is *" do
        a = subject.new('en', '*', q: 0)
        a.reject?('en-us').must_equal true
      end

      it "rejected if the primary_tag and subtag are *" do
        a = subject.new('*', q: 0)
        a.reject?('en-us').must_equal true
      end

      it "not rejected if the primary_tag and subtag don't match" do
        a = subject.new('en', 'us', q: 0)
        a.reject?('en-gb').must_equal false
      end

      it "not rejected if the primary_tag doesn't match" do
        a = subject.new('en', 'us', q: 0)
        a.reject?('zh-us').must_equal false
      end

      it "not rejected if the subtag doesn't match" do
        a = subject.new('en', 'us', q: 0)
        a.reject?('en-gb').must_equal false
      end

      # TODO: test *
      it "not rejected if..." do
        a = subject.new('en', 'us', q: 0)
        a.reject?('*').must_equal false
      end

      it "not rejected if q > 0" do
        a = subject.new('en', 'us', q: 0.001)
        a.reject?('en-us').must_equal false
        a.reject?('en-gb').must_equal false
        a.reject?('zh-us').must_equal false
        b = subject.new('en', '*', q: 0.9)
        b.reject?('en-us').must_equal false
        c = subject.new('*', q: 1)
        c.reject?('en-us').must_equal false
      end

      it "not rejected compared against nil" do
        a = subject.new('en', 'us')
        a.reject?(nil).must_equal false
      end
    end
  end
end
