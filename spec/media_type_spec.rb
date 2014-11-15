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

    it "convers to string" do
      s = subject.new('text', 'html', q: 0.9, params: { 'level' => '1' }).to_s
      s.must_equal "text/html;q=0.9;level=1"
    end
  end
end
