require_relative "spec_helper"
require "open3"
require "rbconfig"

describe "supported representation validation" do
  [
    [AcceptHeaders::MediaType::Negotiator, 'text/plain', '*/*', 'Accept: text/plain'],
    [AcceptHeaders::Encoding::Negotiator, 'gzip', '*', 'Accept-Encoding: gzip'],
    [AcceptHeaders::Language::Negotiator, 'en-US', '*', 'Accept-Language: en-US']
  ].each do |negotiator_class, valid, wildcard, prefixed|
    describe negotiator_class.name do
      it "rejects invalid offers before considering any header or other offer" do
        invalid = [nil, false, 42, Object.new, '', ' ', wildcard, prefixed,
                   "#{valid},#{valid}", "#{valid};q=1", "#{valid};Q=1",
                   "#{valid};q=0.5", "#{valid};q=0", "#{valid}\r\n",
                   "#{valid}\0", "#{valid}\x7f", "#{valid}\v",
                   "\xff".b.force_encoding('UTF-8'), valid.encode('UTF-16LE')]
        [nil, '', "#{wildcard};q=0", wildcard].each do |header|
          negotiator = negotiator_class.new(header)
          invalid.each do |value|
            [:negotiate, :accept?].each do |method|
              assert_raises(AcceptHeaders::InvalidSupportedValue, "#{method}: #{value.inspect}") do
                negotiator.public_send(method, [valid, value])
              end
            end
          end
        end
      end

      it "raises ArgumentError for an invalid standalone offer" do
        [false, {}, Object.new].each do |offer|
          assert_raises(AcceptHeaders::InvalidSupportedValue) do
            negotiator_class.new(wildcard).negotiate(offer)
          end
        end
      end

      it "retains nil and empty arrays as no offers" do
        [nil, []].each do |supported|
          negotiator = negotiator_class.new(nil)
          assert_nil negotiator.negotiate(supported)
          assert_equal false, negotiator.accept?(supported)
        end
      end

      it "rejects objects that convert themselves to offer arrays" do
        supported = Object.new
        supported.define_singleton_method(:to_a) { [valid] }
        assert_raises(AcceptHeaders::InvalidSupportedValue) do
          negotiator_class.new(nil).negotiate(supported)
        end
      end

      it "accepts case and optional whitespace without mutating frozen offers" do
        offer = " \t#{valid.upcase}\t ".freeze
        negotiator = negotiator_class.new(wildcard)
        assert_equal true, negotiator.accept?(offer)
        assert_equal " \t#{valid.upcase}\t ", offer
      end
    end
  end

  describe "media type syntax" do
    let(:negotiator) { AcceptHeaders::MediaType::Negotiator.new('*/*') }

    it "rejects incomplete types and malformed parameters throughout the offer" do
      ['text', 'text/*', '*/plain', 'text/plain/', 'text /plain',
       'text/plain;note', 'text/plain;note=', 'text/plain;=value',
       'text/plain;note=two words', 'text/plain;note="unclosed',
       'text/plain;note="closed"junk', 'text/plain;note="trailing' + "\\",
       'text/plain;note="valid";broken', 'text/plain; Q = "1"',
       'text/plain;note="a,b" , application/json', 'text/plain,garbage',
       "text/plain;note=\"line\nbreak\"", "text/plain;note=\"escaped\\\nbreak\""].each do |offer|
        assert_raises(AcceptHeaders::InvalidSupportedValue, offer) { negotiator.negotiate(offer) }
      end
    end

    it "preserves quoted delimiters, escapes, quality text, and non-ASCII values" do
      offer = 'Text/Plain;note="a,b;c\\"d\\\\e;q=1";label="café"'.freeze
      result = negotiator.negotiate(offer)
      assert_equal 'text/plain', result.media_range
      assert_equal({'note' => 'a,b;c"d\\e;q=1', 'label' => "caf\u00e9"}, result.extensions)
    end

    it "preserves quoted obs-text bytes" do
      offer = "text/plain;note=\"\x80\xff\"".b.freeze
      result = negotiator.negotiate(offer)
      assert_equal "\x80\xff".b, result.extensions['note']
    end

    it "accepts empty parameter segments and empty quoted values" do
      result = negotiator.negotiate('text/plain; ; note="";;')
      assert_equal({'note' => ''}, result.extensions)
    end
  end

  it "exposes the shared exception through each direct negotiator require" do
    %w[media_type encoding language].each do |kind|
      script = "require 'accept_headers/#{kind}/negotiator'; " \
        "abort unless AcceptHeaders::InvalidSupportedValue < ArgumentError"
      output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', '-e', script)
      assert status.success?, output
    end
  end
end
