require_relative "../spec_helper"

module AcceptHeaders
  class Language
    describe Negotiator do
      subject do
        AcceptHeaders::Language::Negotiator
      end

      describe "parsing an accept header" do
        it "returns a sorted array of media primary tags" do
          subject.new("en-*;q=0.2, en-us").list.must_equal [
            Language.new('en', 'us'),
            Language.new('en', '*', q: 0.2)
          ]

          subject.new("en-*, en-us, *;q=0.8").list.must_equal [
            Language.new('en', 'us'),
            Language.new('en', '*'),
            Language.new('*', '*', q: 0.8)
          ]
        end

        it "ignores the 'Accept-Language:' prefix" do
          subject.new('Accept-Language: en-us').list.must_equal [
            Language.new('en', 'us')
          ]
        end

        it "sets media primary tag to */* when the accept header is empty" do
          subject.new('').list.must_equal [
            Language.new('*', '*')
          ]
        end

        it "sets media primary tag to */* when the primary tag is only *" do
          subject.new('*').list.must_equal [
            Language.new('*', '*')
          ]
        end

        it "defaults q to 1 if it's not explicitly specified" do
          subject.new("en-us").list.must_equal [
            Language.new('en', 'plain', q: 1.0)
          ]
        end

        it "strips whitespace from between media primary tags" do
          subject.new("\ten-us\r,\nen-gb\s").list.must_equal [
            Language.new('en', 'us'),
            Language.new('en', 'gb')
          ]
        end

        it "strips whitespace around q" do
          subject.new("en-us;\tq\r=\n1, en-gb").list.must_equal [
            Language.new('en', 'us'),
            Language.new('en', 'gb')
          ]
        end

        it "has a q value of 0.001 when parsed q is invalid" do
          subject.new("en-us;q=x").list.must_equal [
            Language.new('en', 'plain', q: 0.001)
          ]
        end

        it "skips invalid media primary tags" do
          subject.new("en-us, en-us-omg;q=0.9").list.must_equal [
            Language.new('en', 'us', q: 1)
          ]
        end
      end

      describe "negotiate supported languages" do
        it "returns a best matching language" do
          match = Language.new('en', 'us')
          n = subject.new('en-*, en-us, *;q=0.8')
          n.negotiate('en-us').must_equal match
        end
      end
    end
  end
end
