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

    it "raises an OutOfRangeError unless q value is between 0 and 1" do
      [-1.0, -0.1, 1.1].each do |q|
        e = -> do
          subject.new('text', 'html', q: q)
        end.must_raise MediaType::OutOfRangeError

        e.message.must_equal "q must be between 0 and 1"
      end

      subject.new('text', 'html', q: 1)
      subject.new('text', 'html', q: 0)
    end

    it "raises an InvalidPrecisionError if q has more than a precision of 3" do
      e = -> do
        subject.new('text', 'html', q: 0.1234)
      end.must_raise MediaType::InvalidPrecisionError

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

    describe "parsing an accept header" do
      it "returns a sorted array of media types" do
        subject.parse("audio/*; q=0.2, audio/basic").must_equal [
          MediaType.new("audio", "basic"),
          MediaType.new("audio", '*', q: 0.2)
        ]
        subject.parse("text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c").must_equal [
          MediaType.new('text', 'html'),
          MediaType.new('text', 'x-c'),
          MediaType.new('text', 'x-dvi', q: 0.8),
          MediaType.new('text', 'plain', q: 0.5)
        ]

        subject.parse("text/*, text/html, text/html;level=1, */*").must_equal [
          MediaType.new('text', 'html', params: { 'level' => '1' }),
          MediaType.new('text', 'html'),
          MediaType.new('text', '*'),
          MediaType.new('*', '*')
        ]

        subject.parse("text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5").must_equal [
          MediaType.new('text', 'html', params: { 'level' => '1' }),
          MediaType.new('text', 'html', q: 0.7),
          MediaType.new('*', '*', q: 0.5),
          MediaType.new('text', 'html', q: 0.4, params: { 'level' => '2' }),
          MediaType.new('text', '*', q: 0.3)
        ]
      end

      it "sets media type to */* when the accept header is empty" do
        subject.parse('').must_equal [
          MediaType.new('*', '*')
        ]
      end

      it "sets media type to */* when the type is only *" do
        subject.parse('*').must_equal [
          MediaType.new('*', '*')
        ]
      end

      it "defaults q to 1 if it's not explicitly specified" do
        subject.parse("text/plain").must_equal [
          MediaType.new('text', 'plain', q: 1.0)
        ]
      end

      it "strips whitespace from between media types" do
        subject.parse("\ttext/plain\r,\napplication/json\s").must_equal [
          MediaType.new('text', 'plain'),
          MediaType.new('application', 'json')
        ]
      end

      it "strips whitespace around q and params" do
        subject.parse("text/plain;\tq\r=\n1, application/json;q=0.8;\slevel\t\t=\r\n1\n").must_equal [
          MediaType.new('text', 'plain'),
          MediaType.new('application', 'json', q: 0.8, params: { "level" => "1" })
        ]
      end

      it "has a q value of 0.001 when parsed q is invalid" do
        subject.parse("text/plain;q=x").must_equal [
          MediaType.new('text', 'plain', q: 0.001)
        ]
      end

      it "raises ParseError when media type contains more than 1 slash" do
        e = -> do
          subject.parse("text/plain/omg;q=0.9")
        end.must_raise MediaType::ParseError

        e.message.must_equal "Unable to parse type and subtype"
      end
    end
  end
end
