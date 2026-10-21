require_relative "spec_helper"

describe AcceptHeaders::MediaType do
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

  it "strips and downcases parameter names while preserving values" do
    subject.new('*', '*', extensions: { "\s\nLEVEL\r\t" => "\t\nX\s\n"}).extensions['level'].must_equal "\t\nX\s\n"
  end

  it "optionally supports a q argument" do
    subject.new('text', 'html', q: 0.8).q.must_equal 0.8
  end

  it "optionally supports a extensions argument" do
    subject.new('text', 'html', extensions: { 'level' => '1' }).extensions['level'].must_equal '1'
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
    end.must_raise AcceptHeaders::MediaType::InvalidQError

    e.message.must_match INVALID_FLOAT_PATTERN

    subject.new('text', 'html', q: '1')
  end

  it "raises an InvalidQError unless q value is between 0 and 1" do
    [-1.0, -0.1, 1.1].each do |q|
      e = -> do
        subject.new('text', 'html', q: q)
      end.must_raise AcceptHeaders::MediaType::InvalidQError

      e.message.must_equal "q must be between 0 and 1"
    end

    subject.new('text', 'html', q: 1)
    subject.new('text', 'html', q: 0)
  end

  it "raises an InvalidQError if q has more than a precision of 3" do
    e = -> do
      subject.new('text', 'html', q: 0.1234)
    end.must_raise AcceptHeaders::MediaType::InvalidQError

    e.message.must_equal "q must be at most 3 decimal places"

    subject.new('text', 'html', q: 0.123)
  end

  it "converts to hash" do
    subject.new('text', 'html').to_h.must_equal({
      type: 'text',
      subtype: 'html',
      q: 1.0,
      extensions: {}
    })
  end

  it "converts to string" do
    s = subject.new('text', 'html', q: 0.9, extensions: { 'level' => '1' }).to_s
    s.must_equal "text/html;level=1;q=0.9"
  end

  it "quotes parameter delimiters and escapes quotes and backslashes" do
    value = subject.new('text', 'html', extensions: { 'note' => 'a,b;c"d\\e', 'empty' => '' })
    value.to_s.must_equal 'text/html;note="a,b;c\\"d\\\\e";empty="";q=1'
  end

  it "outputs the media range" do
    subject.new('text', 'html', extensions: { 'level' => '1' }).media_range.must_equal "text/html"
  end

  describe "#content_type" do
    it "outputs type, subtype, and parameters without the quality weight" do
      media_type = subject.new('text', 'html', q: 0.9, extensions: { 'level' => '1' })

      media_type.content_type.must_equal 'text/html;level=1'
      media_type.to_s.must_equal 'text/html;level=1;q=0.9'
      media_type.media_range.must_equal 'text/html'
    end

    it "does not add a quality parameter when there are no media parameters" do
      subject.new('application', 'json').content_type.must_equal 'application/json'
    end

    it "uses the same parameter quoting as the Accept representation" do
      {
        'a,b' => '"a,b"',
        'a;b' => '"a;b"',
        'a"b' => '"a\\"b"',
        'a\\b' => '"a\\\\b"',
        '' => '""',
        "caf\u00e9" => "\"caf\u00e9\"",
        "\x80\xFF".b => "\"\x80\xFF\"".b
      }.each do |parameter, encoded|
        media_type = subject.new('text', 'plain', extensions: { 'note' => parameter })

        media_type.content_type.must_equal "text/plain;note=#{encoded}"
        media_type.to_s.must_equal "text/plain;note=#{encoded};q=1"
      end
    end

    it "does not mutate the media type or parameter values" do
      parameter = 'a,b;c"d\\e'.freeze
      extensions = { 'note' => parameter }.freeze
      media_type = subject.new('text', 'plain', q: 0.8, extensions: extensions)
      original = media_type.to_h
      result = media_type.content_type
      result.replace('application/json')

      media_type.to_h.must_equal original
      media_type.extensions.must_equal extensions
      media_type.content_type.must_equal 'text/plain;note="a,b;c\\"d\\\\e"'
      media_type.to_s.must_equal 'text/plain;note="a,b;c\\"d\\\\e";q=0.8'
    end
  end

  describe "#match" do
    it "preserves raw comparison for hand-built non-String parameter values" do
      [2, :public, nil].each do |value|
        range = subject.new('application', 'json', extensions: { 'version' => value })
        excluded = subject.new('application', 'json', q: 0, extensions: { 'version' => value })

        ['application/json;version=2', 'application/json;version=public'].each do |candidate|
          range.match(candidate).must_equal false
          range.accept?(candidate).must_equal false
          excluded.reject?(candidate).must_equal false
        end

        expected = value.nil?
        range.match('application/json').must_equal expected
        range.accept?('application/json').must_equal expected
        excluded.reject?('application/json').must_equal expected
      end
    end

    it "folds only ASCII case in charset values" do
      { 'UTF-8' => 'utf-8', 'É' => 'é', 'K' => 'k' }.each do |value, candidate|
        range = subject.new('text', 'plain', extensions: { 'charset' => value })
        excluded = subject.new('text', 'plain', q: 0, extensions: { 'charset' => value })
        header = "text/plain;charset=\"#{candidate}\""
        expected = value == 'UTF-8'

        range.match(header).must_equal expected
        range.accept?(header).must_equal expected
        excluded.reject?(header).must_equal expected
      end
    end
  end

  describe "#accept?" do
    it "matches type and subtype without case sensitivity" do
      subject.new('text', 'html').accept?('TEXT/HTML').must_equal true
    end

    it "requires every media range parameter to match the supported representation" do
      range = subject.new('application', 'json', extensions: { 'version' => '2' })
      range.accept?('application/json').must_equal false
      range.accept?('application/json;version=1').must_equal false
      range.accept?('application/json;VERSION=2').must_equal true
      range.accept?('application/json;version=2;profile=public').must_equal true
    end

    it "matches charset values without case sensitivity" do
      range = subject.new('text', 'plain', extensions: { 'charset' => 'UTF-8' })
      range.accept?('text/plain;charset=utf-8').must_equal true
      range.accept?('text/plain;charset=iso-8859-1').must_equal false
      range.accept?('text/plain').must_equal false
    end

    it "preserves case sensitivity for other parameter values" do
      range = subject.new('application', 'json', extensions: { 'profile' => 'Public' })
      range.accept?('application/json;profile=Public').must_equal true
      range.accept?('application/json;profile=public').must_equal false
    end

    it "does not match an empty candidate or a list of candidates" do
      range = subject.new('*')
      range.accept?('').must_equal false
      range.accept?('text/html,application/json').must_equal false
    end

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

    it "not accepted compared against nil" do
      subject.new('text', 'html').accept?(nil).must_equal false
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

      it "not rejected compared against nil" do
        subject.new('text', 'html').reject?(nil).must_equal false
      end

      # TODO: test *
      it "not rejected if..." do
        a = subject.new('text', 'plain', q: 0)
        a.reject?('*').must_equal false
      end
    end
  end
end
