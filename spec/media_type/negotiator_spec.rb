require_relative "../spec_helper"

module AcceptHeaders
  class MediaType
    describe Negotiator do
      subject do
        AcceptHeaders::MediaType::Negotiator
      end

      describe "parsing an accept header" do
        it "returns a sorted array of media types" do
          subject.new("audio/*; q=0.2, audio/basic").list.must_equal [
            MediaType.new('audio', 'basic'),
            MediaType.new('audio', '*', q: 0.2)
          ]
          subject.new("text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c").list.must_equal [
            MediaType.new('text', 'html'),
            MediaType.new('text', 'x-c'),
            MediaType.new('text', 'x-dvi', q: 0.8),
            MediaType.new('text', 'plain', q: 0.5)
          ]

          subject.new("text/*, text/html, text/html;level=1, */*").list.must_equal [
            MediaType.new('text', 'html', params: { 'level' => '1' }),
            MediaType.new('text', 'html'),
            MediaType.new('text', '*'),
            MediaType.new('*', '*')
          ]

          subject.new("text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5").list.must_equal [
            MediaType.new('text', 'html', params: { 'level' => '1' }),
            MediaType.new('text', 'html', q: 0.7),
            MediaType.new('*', '*', q: 0.5),
            MediaType.new('text', 'html', q: 0.4, params: { 'level' => '2' }),
            MediaType.new('text', '*', q: 0.3)
          ]
        end

        it "supports all registered IANA media types" do
          require 'csv'
          # https://www.iana.org/assignments/media-types/media-types.xhtml
          %w[application audio image message model multipart text video].each do |filename|
            CSV.foreach("spec/support/#{filename}.csv", headers: true) do |row|
              media_type = row['Template']

              # audio/amr-wb+ is a typo
              media_type = 'audio/amr-wb+' if media_type == 'amr-wb+'

              if media_type
                subject.new(media_type).list.size.must_equal 1
                subject.new(media_type).list.first.to_s.start_with?(media_type.downcase).must_equal true
              end
            end
          end
        end

        it "sets media type to */* when the accept header is empty" do
          subject.new('').list.must_equal [
            MediaType.new('*', '*')
          ]
        end

        it "sets media type to */* when the type is only *" do
          subject.new('*').list.must_equal [
            MediaType.new('*', '*')
          ]
        end

        it "defaults q to 1 if it's not explicitly specified" do
          subject.new("text/plain").list.must_equal [
            MediaType.new('text', 'plain', q: 1.0)
          ]
        end

        it "strips whitespace from between media types" do
          subject.new("\ttext/plain\r,\napplication/json\s").list.must_equal [
            MediaType.new('text', 'plain'),
            MediaType.new('application', 'json')
          ]
        end

        it "strips whitespace around q and params" do
          subject.new("text/plain;\tq\r=\n1, application/json;q=0.8;\slevel\t\t=\r\n1\n").list.must_equal [
            MediaType.new('text', 'plain'),
            MediaType.new('application', 'json', q: 0.8, params: { "level" => "1" })
          ]
        end

        it "has a q value of 0.001 when parsed q is invalid" do
          subject.new("text/plain;q=x").list.must_equal [
            MediaType.new('text', 'plain', q: 0.001)
          ]
        end

        it "skips invalid media types" do
          subject.new("text/html, text/plain/omg;q=0.9").list.must_equal [
            MediaType.new('text', 'html', q: 1)
          ]
        end
      end

      describe "negotiate supported media types" do
        it "returns a best matching media type" do
          n = subject.new("text/*, text/html, text/html;level=1, */*")
          n.negotiate("text/html").must_equal MediaType.new('text', 'html', params: { 'level' => '1' })
        end
      end
    end
  end
end