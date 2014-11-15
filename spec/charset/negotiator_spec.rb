require_relative "../spec_helper"

module AcceptHeaders
  class Charset
    describe Negotiator do
      subject do
        AcceptHeaders::Charset::Negotiator
      end

      describe "parsing an accept header" do
        it "returns a sorted array of charsets" do
          subject.new("*; q=0.2, unicode-1-1").list.must_equal [
            Charset.new('unicode-1-1'),
            Charset.new('*', q: 0.2)
          ]

          subject.new("us-ascii; q=0.5, iso-8859-1, utf-8; q=0.8, macintosh").list.must_equal [
            Charset.new('iso-8859-1'),
            Charset.new('macintosh'),
            Charset.new('utf-8', q: 0.8),
            Charset.new('us-ascii', q: 0.5)
          ]
        end

        it "sets charset to * when the accept-charset header is empty" do
          subject.new('').list.must_equal [
            Charset.new('*')
          ]
        end

        it "defaults q to 1 if it's not explicitly specified" do
          subject.new("iso-8859-1").list.must_equal [
            Charset.new('iso-8859-1', q: 1.0)
          ]
        end

        it "strips whitespace from between charsets" do
          subject.new("\tunicode-1-1\r,\niso-8859-1\s").list.must_equal [
            Charset.new('unicode-1-1'),
            Charset.new('iso-8859-1')
          ]
        end

        it "strips whitespace around q" do
          subject.new("iso-8859-1;\tq\r=\n1, unicode-1-1;q=0.8\n").list.must_equal [
            Charset.new('iso-8859-1'),
            Charset.new('unicode-1-1', q: 0.8)
          ]
        end

        it "has a q value of 0.001 when parsed q is invalid" do
          subject.new("iso-8859-1;q=x").list.must_equal [
            Charset.new('iso-8859-1', q: 0.001)
          ]
        end

        it "skips invalid character sets" do
          subject.new("iso-8859-1, @unicode-1-1").list.must_equal [
            Charset.new('iso-8859-1', q: 1)
          ]
        end
      end

      describe "negotiate supported charsets" do
        it "returns a best matching charset" do
          match = Charset.new('iso-8859-1')
          n = subject.new('us-ascii; q=0.5, iso-8859-1, utf-8; q=0.8, macintosh')
          n.negotiate('iso-8859-1').must_equal match
        end
      end
    end
  end
end
