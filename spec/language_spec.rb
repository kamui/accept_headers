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

    it "raises an InvalidQError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('en', 'us', q: q)
        end.must_raise Language::InvalidQError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('en', 'us', q: 1)
      subject.new('en', 'gb', q: 0)
    end

    it "raises an InvalidQError if q has more than a precision of 3" do
      e = -> do
        subject.new('en', 'us', q: 0.1234)
      end.must_raise Language::InvalidQError

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

    it "outputs the language tag" do
      subject.new('en', 'us', q: 0.9).language_tag.must_equal "en-us"
    end
  end
end
