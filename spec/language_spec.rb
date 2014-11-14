require_relative "spec_helper"

module AcceptHeaders
  describe Language do
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
      end.must_raise Language::InvalidQError

      e.message.must_equal 'invalid value for Float(): "a"'

      subject.new('en', 'us', q: '1')
    end

    it "raises an OutOfRangeError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('en', 'us', q: q)
        end.must_raise Language::OutOfRangeError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('en', 'us', q: 1)
      subject.new('en', 'gb', q: 0)
    end

    it "raises an InvalidPrecisionError if q has more than a precision of 3" do
      e = -> do
        subject.new('en', 'us', q: 0.1234)
      end.must_raise Language::InvalidPrecisionError

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

    it "convers to string" do
      s = subject.new('en', 'us', q: 0.9).to_s
      s.must_equal "en-us;q=0.9"
    end

    describe "parsing an accept header" do
      it "returns a sorted array of media primary tags" do
        subject.parse("en-*;q=0.2, en-us").must_equal [
          Language.new('en', 'us'),
          Language.new('en', '*', q: 0.2)
        ]

        subject.parse("en-*, en-us, *;q=0.8").must_equal [
          Language.new('en', 'us'),
          Language.new('en', '*'),
          Language.new('*', '*', q: 0.8)
        ]
      end

      it "sets media primary tag to */* when the accept header is empty" do
        subject.parse('').must_equal [
          Language.new('*', '*')
        ]
      end

      it "sets media primary tag to */* when the primary tag is only *" do
        subject.parse('*').must_equal [
          Language.new('*', '*')
        ]
      end

      it "defaults q to 1 if it's not explicitly specified" do
        subject.parse("en-us").must_equal [
          Language.new('en', 'plain', q: 1.0)
        ]
      end

      it "strips whitespace from between media primary tags" do
        subject.parse("\ten-us\r,\nen-gb\s").must_equal [
          Language.new('en', 'us'),
          Language.new('en', 'gb')
        ]
      end

      it "strips whitespace around q" do
        subject.parse("en-us;\tq\r=\n1, en-gb").must_equal [
          Language.new('en', 'us'),
          Language.new('en', 'gb')
        ]
      end

      it "has a q value of 0.001 when parsed q is invalid" do
        subject.parse("en-us;q=x").must_equal [
          Language.new('en', 'plain', q: 0.001)
        ]
      end

      it "skips invalid media primary tags" do
        subject.parse("en-us, en-us-omg;q=0.9").must_equal [
          Language.new('en', 'us', q: 1)
        ]
      end
    end
  end
end
