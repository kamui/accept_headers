require_relative "../spec_helper"

describe AcceptHeaders::MediaType::Negotiator do
  subject { AcceptHeaders::MediaType::Negotiator }
  let(:media_type) { AcceptHeaders::MediaType }

  describe "parsing an accept header" do
    it "returns a sorted array of media types" do
      subject.new("audio/*; q=0.2, audio/basic").list.must_equal [
        media_type.new('audio', 'basic'),
        media_type.new('audio', '*', q: 0.2)
      ]
      subject.new("text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c").list.must_equal [
        media_type.new('text', 'html'),
        media_type.new('text', 'x-c'),
        media_type.new('text', 'x-dvi', q: 0.8),
        media_type.new('text', 'plain', q: 0.5)
      ]

      subject.new("text/*, text/html, text/html;level=1, */*").list.must_equal [
        media_type.new('text', 'html', extensions: { 'level' => '1' }),
        media_type.new('text', 'html'),
        media_type.new('text', '*'),
        media_type.new('*', '*')
      ]

      subject.new("text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5").list.must_equal [
        media_type.new('text', 'html', extensions: { 'level' => '1' }),
        media_type.new('text', 'html', q: 0.7),
        media_type.new('*', '*', q: 0.5),
        media_type.new('text', 'html', q: 0.4, extensions: { 'level' => '2' }),
        media_type.new('text', '*', q: 0.3)
      ]
    end

    it "ignores the 'Accept:' prefix" do
      subject.new('Accept: text/html').list.must_equal [
        media_type.new('text', 'html')
      ]
    end

    it "supports all registered IANA media types" do
      require 'csv'
      # https://www.iana.org/assignments/media-types/media-types.xhtml
      %w[application audio image message model multipart text video].each do |filename|
        CSV.foreach("spec/support/media_types/#{filename}.csv", headers: true) do |row|
          media_range = row['Template']

          if media_range
            subject.new(media_range).list.size.must_equal 1
            subject.new(media_range).list.first.media_range.must_equal media_range.downcase
          end
        end
      end
    end

    it "sets media type to */* when the accept header is empty" do
      subject.new('').list.must_equal [
        media_type.new('*', '*')
      ]
    end

    it "sets media type to */* when the type is only *" do
      subject.new('*').list.must_equal [
        media_type.new('*', '*')
      ]
    end

    it "defaults q to 1 if it's not explicitly specified" do
      subject.new("text/plain").list.must_equal [
        media_type.new('text', 'plain', q: 1.0)
      ]
    end

    it "strips whitespace from between media types" do
      subject.new("\ttext/plain\r,\napplication/json\s").list.must_equal [
        media_type.new('text', 'plain'),
        media_type.new('application', 'json')
      ]
    end

    it "strips whitespace around q and extensions" do
      subject.new("text/plain;\tq\r=\n1, application/json;q=0.8;\slevel\t\t=\r\n1\n").list.must_equal [
        media_type.new('text', 'plain'),
        media_type.new('application', 'json', q: 0.8, extensions: { "level" => "1" })
      ]
    end

    it "has a q value of 0.001 when parsed q is invalid" do
      subject.new("text/plain;q=x").list.must_equal [
        media_type.new('text', 'plain', q: 0.001)
      ]
    end

    it "parses extensions with quoted values" do
      subject.new('text/html;q=1;version="2";level="a;b;cc\'cd", text/html;version=\'1\';level=\'\blah;x;1;;\'').list.must_equal [
        media_type.new('text', 'html', extensions: { 'version' => '2', 'level' => 'a;b;cc\'cd'}),
        media_type.new('text', 'html', extensions: { 'version' => '1', 'level' => '\'\blah;x;1;;\''})
      ]
    end

    it "skips invalid media types" do
      subject.new("text/html, text/plain/omg;q=0.9").list.must_equal [
        media_type.new('text', 'html', q: 1)
      ]
    end
  end

  describe "#to_s" do
    it "returns a string of each media type #to_s joined by a comma" do
      subject.new("text/html;level=1, text/plain;q=0.9").to_s.must_equal "text/html;q=1;level=1,text/plain;q=0.9"
    end
  end

  describe "#negotiate" do
    it "returns a best matching media type" do
      all_browsers.each do |browser|
        browser = subject.new(browser[:accept])

        browser.negotiate('text/html').must_equal media_type.new(
          'text',
          'html'
        )

        browser.negotiate(['text/html', 'application/xhtml+xml']).must_equal media_type.new(
          'text',
          'html'
        )

        browser.negotiate(['application/xhtml+xml', 'application/json']).must_equal media_type.new(
          'application',
          'xhtml+xml'
        )
      end

      [chrome, firefox, safari].each do| browser|
        browser = subject.new(browser[:accept])

        browser.negotiate(['application/xml']).must_equal media_type.new(
          'application',
          'xml'
        )

        browser.negotiate(['application/json']).must_equal media_type.new(
          'application',
          'json'
        )
      end

      api = subject.new('application/json;q=1;version=2,application/json;q=0.9;version=1')
      api.negotiate('text/html').must_be_nil
      api.negotiate('application/xml').must_be_nil
      api.negotiate(['application/xml', 'application/json']).must_be_nil
      api.negotiate(['application/json;version=1', 'application/json;version=2']).to_h.must_equal media_type.new(
        'application',
        'json',
        extensions: {
          'version' => '2'
        }
      ).to_h

      q0 = subject.new('application/json,application/xml;q=0')
      q0.negotiate('application/json').must_equal media_type.new(
        'application',
        'json'
      )
      q0.negotiate('application/xml').must_be_nil
      q0.negotiate(['application/json', 'application/xml']).must_equal media_type.new(
        'application',
        'json'
      )
    end

    it "uses the most specific matching range to assign quality before choosing a representation" do
      n = subject.new('text/html;q=0.1,text/*;q=0.9,application/json;q=0.5')
      n.negotiate(['text/html', 'application/json']).media_range.must_equal 'application/json'
      n.negotiate(['text/html', 'text/plain']).media_range.must_equal 'text/plain'
    end

    it "gives matching parameters precedence over a parameterless range" do
      n = subject.new('text/plain;q=0.7,text/plain;format=fixed;q=0.4,image/jpeg;q=0.5')
      n.negotiate(['text/plain;format=fixed', 'image/jpeg']).media_range.must_equal 'image/jpeg'
      n.negotiate(['text/plain', 'image/jpeg']).media_range.must_equal 'text/plain'
    end

    it "treats parameters after q as media parameters" do
      n = subject.new('application/json;q=0.9;version=2')
      n.negotiate('application/json').must_be_nil
      n.negotiate('application/json;version=2').extensions.must_equal('version' => '2')
    end

    it "preserves the parameters of the supported representation" do
      n = subject.new('application/json')
      n.negotiate('application/json;version=2').to_h.must_equal media_type.new(
        'application', 'json', extensions: { 'version' => '2' }
      ).to_h
    end

    it "uses supported order to break equally preferred matching representations" do
      n = subject.new('text/*')
      n.negotiate(['text/plain', 'text/html']).media_range.must_equal 'text/plain'
      n.negotiate(['text/html', 'text/plain']).media_range.must_equal 'text/html'
    end

    it "allows a specific positive quality to override a wildcard exclusion" do
      n = subject.new('text/*;q=0,text/html;q=0.5')
      n.negotiate('text/html').media_range.must_equal 'text/html'
      n.negotiate('text/plain').must_be_nil
    end

    it "excludes only representations matching the rejected parameters" do
      n = subject.new('text/plain;format=fixed;q=0,text/plain;q=1')
      n.negotiate('text/plain;format=fixed').must_be_nil
      n.negotiate('text/plain;format=flowed').extensions.must_equal('format' => 'flowed')
    end

    it "rejects matching q=0 even if it matches media ranges where q > 0" do
      n = subject.new('application/xml;q=0,*/*')
      n.negotiate('application/xml').must_be_nil

      n2 = subject.new('application/xml;q=0,application/xml;q=1')
      n2.negotiate('application/xml').must_be_nil
    end
  end

  describe "#accept?" do
    it "returns whether specific media type is accepted" do
      n = subject.new('video/*, text/html, text/html;level=1;q:0.8')
      n.accept?('text/html').must_equal true
      n.accept?('application/json').must_equal false
      n.accept?('video/ogg').must_equal true
      n.accept?(['text/html','application/json']).must_equal true
      n.accept?(['application/xml','application/json']).must_equal false
    end

    it "returns false if accepted but q=0" do
      n = subject.new('video/*, text/html;q=0')
      n.accept?('text/html').must_equal false
      n.accept?('video/ogg').must_equal true
    end

    it "returns false when q=0 even if it matches media ranges where q > 0" do
      n = subject.new('application/xml;q=0,*/*')
      n.accept?('application/xml').must_equal false

      n2 = subject.new('application/xml;q=0,application/xml;q=1')
      n2.accept?('application/xml').must_equal false
    end
  end
end
