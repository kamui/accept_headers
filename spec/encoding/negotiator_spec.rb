require_relative "../spec_helper"

module AcceptHeaders
  class Encoding
    describe Negotiator do
      subject do
        AcceptHeaders::Encoding::Negotiator
      end

      describe "parsing an accept header" do
        it "returns a sorted array of encodings" do
          subject.new("*; q=0.2, compress").list.must_equal [
            Encoding.new('compress'),
            Encoding.new('*', q: 0.2)
          ]

          subject.new("deflate; q=0.5, gzip, compress; q=0.8, identity").list.must_equal [
            Encoding.new('gzip'),
            Encoding.new('identity'),
            Encoding.new('compress', q: 0.8),
            Encoding.new('deflate', q: 0.5)
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
            Encoding.new('*')
          ]
        end

        it "defaults q to 1 if it's not explicitly specified" do
          subject.new("gzip").list.must_equal [
            Encoding.new('gzip', q: 1.0)
          ]
        end

        it "strips whitespace from between encodings" do
          subject.new("\tcompress\r,\ngzip\s").list.must_equal [
            Encoding.new('compress'),
            Encoding.new('gzip')
          ]
        end

        it "strips whitespace around q" do
          subject.new("gzip;\tq\r=\n1, compress;q=0.8\n").list.must_equal [
            Encoding.new('gzip'),
            Encoding.new('compress', q: 0.8)
          ]
        end

        it "has a q value of 0.001 when parsed q is invalid" do
          subject.new("gzip;q=x").list.must_equal [
            Encoding.new('gzip', q: 0.001)
          ]
        end

        it "skips invalid encodings" do
          subject.new("gzip, @blah").list.must_equal [
            Encoding.new('gzip', q: 1.0)
          ]
        end
      end

      describe "negotiate supported encodings" do
        it "returns a best matching encoding" do
          match =
          n = subject.new("deflate; q=0.5, gzip, compress; q=0.8, identity")
          n.negotiate("identity").must_equal Encoding.new('identity')
        end
      end
    end
  end
end
