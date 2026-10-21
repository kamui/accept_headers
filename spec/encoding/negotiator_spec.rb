require_relative "../spec_helper"

describe AcceptHeaders::Encoding::Negotiator do
  subject { AcceptHeaders::Encoding::Negotiator }
  let(:encoding) { AcceptHeaders::Encoding }

  describe "parsing an accept header" do
    it "returns a sorted array of encodings" do
      subject.new("*; q=0.2, compress").list.must_equal [
        encoding.new('compress'),
        encoding.new('*', q: 0.2)
      ]

      subject.new("deflate; q=0.5, gzip, compress; q=0.8, identity").list.must_equal [
        encoding.new('gzip'),
        encoding.new('identity'),
        encoding.new('compress', q: 0.8),
        encoding.new('deflate', q: 0.5)
      ]
    end

    it "ignores the 'Accept-Encoding:' prefix" do
      subject.new('Accept-Encoding: gzip').list.must_equal [
        encoding.new('gzip')
      ]
    end

    it "parses content codings in the bundled IANA snapshot" do
      require 'csv'
      # https://www.iana.org/assignments/http-parameters/http-parameters.xml#content-coding
      CSV.foreach("spec/support/encodings/content-coding.csv", headers: true) do |row|
        encoding = row['Name']

        if encoding
          subject.new(encoding).list.size.must_equal 1
          subject.new(encoding).list.first.encoding.must_equal encoding.downcase
        end
      end
    end

    it "allows only identity when the accept-encoding header is empty" do
      ['', " \t", 'Accept-Encoding:', 'accept-encoding: '].each do |header|
        subject.new(header).list.map(&:encoding).must_equal ['identity']
      end
    end

    it "allows any content coding when the accept-encoding header is absent" do
      subject.new(nil).list.map(&:encoding).must_equal ['*']
    end

    it "defaults q to 1 if it's not explicitly specified" do
      subject.new("gzip").list.must_equal [
        encoding.new('gzip', q: 1.0)
      ]
    end

    it "strips whitespace from between encodings" do
      subject.new("\tcompress\r,\ngzip\s").list.must_equal [
        encoding.new('compress'),
        encoding.new('gzip')
      ]
    end

    it "strips whitespace around q" do
      subject.new("gzip;\tq\r=\n1, compress;q=0.8\n").list.must_equal [
        encoding.new('gzip'),
        encoding.new('compress', q: 0.8)
      ]
    end

    it "has a q value of 0.001 when parsed q is invalid" do
      subject.new("gzip;q=x").list.must_equal [
        encoding.new('gzip', q: 0.001)
      ]
    end

    it "skips invalid encodings" do
      subject.new("gzip, @blah").list.must_equal [
        encoding.new('gzip', q: 1.0)
      ]
    end

    it "parses HTTP token characters and skips delimiter-containing coding names" do
      subject.new('example.coding, bad{coding}, bad\\coding').list.map(&:encoding).must_equal ['example.coding']
    end
  end

  describe "#to_s" do
    it "returns a string of each encoding #to_s joined by a comma" do
      subject.new("compress,gzip;q=0.9").to_s.must_equal "compress;q=1,gzip;q=0.9"
    end
  end

  describe "negotiate supported encodings" do
    it "returns a best matching encoding" do
      n = subject.new('deflate; q=0.5, gzip, compress; q=0.8, identity')
      n.negotiate(['identity', 'deflate']).encoding.must_equal 'identity'
    end

    it "distinguishes an absent header from an empty field value" do
      subject.new(nil).negotiate('gzip').encoding.must_equal 'gzip'
      ['', " \t", 'Accept-Encoding:'].each do |header|
        negotiator = subject.new(header)
        negotiator.negotiate('gzip').must_be_nil
        negotiator.negotiate(['gzip', 'identity']).encoding.must_equal 'identity'
      end
    end

    it "prefers an acceptable coding over implicit identity" do
      subject.new('gzip;q=0.5').negotiate(['identity', 'gzip']).encoding.must_equal 'gzip'
      subject.new('*;q=0.5').negotiate(['identity', 'br']).encoding.must_equal 'br'
    end

    it "falls back to identity without accepting unlisted content codings" do
      negotiator = subject.new('gzip')
      negotiator.negotiate(['br', 'identity']).encoding.must_equal 'identity'
      negotiator.accept?('identity').must_equal true
      negotiator.negotiate('br').must_be_nil
    end

    it "does not turn another coding's rejection into an identity rejection" do
      negotiator = subject.new('gzip;q=0')
      negotiator.negotiate(['gzip', 'identity']).encoding.must_equal 'identity'
      negotiator.accept?('gzip').must_equal false
    end

    it "honors explicit identity preferences and exclusions" do
      subject.new('gzip;q=0.5, identity;q=0.8').negotiate(['gzip', 'identity']).encoding.must_equal 'identity'
      subject.new('identity;q=0').negotiate('identity').must_be_nil
      subject.new('*;q=0').negotiate('identity').must_be_nil
      subject.new('*;q=0, identity;q=0.5').negotiate('identity').encoding.must_equal 'identity'
    end

    it "matches supported coding names without case sensitivity" do
      subject.new('GZIP').negotiate('GZip').encoding.must_equal 'gzip'
      subject.new('br').negotiate('IDENTITY').encoding.must_equal 'identity'
    end

    it "requires supported names to be complete HTTP tokens" do
      negotiator = subject.new('*')
      ['gzip\\bad', 'gzip{bad}', "gzip\nidentity", 'gzip,br'].each do |coding|
        assert_raises(AcceptHeaders::InvalidSupportedValue) { negotiator.negotiate(coding) }
      end
    end
  end
end
