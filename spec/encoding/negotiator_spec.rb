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

    it "supports all registered IANA encodings" do
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

    it "sets encoding to * when the accept-encoding header is empty" do
      subject.new('').list.must_equal [
        encoding.new('*')
      ]
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
  end

  describe "#to_s" do
    it "returns a string of each encoding #to_s joined by a comma" do
      subject.new("compress,gzip;q=0.9").to_s.must_equal "compress;q=1,gzip;q=0.9"
    end
  end

  describe "negotiate supported encodings" do
    it "returns a best matching encoding" do
      n = subject.new('deflate; q=0.5, gzip, compress; q=0.8, identity')
      n.negotiate(['identity', 'deflate']).must_equal encoding.new('identity')
    end
  end
end
