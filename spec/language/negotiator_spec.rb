require_relative "../spec_helper"

describe AcceptHeaders::Language::Negotiator do
  subject { AcceptHeaders::Language::Negotiator }

  describe "parsing an Accept-Language header" do
    it "sorts ranges by quality and specificity" do
      subject.new('en;q=0.2, en-us').list.map(&:to_h).must_equal [
        {primary_tag: 'en', subtag: 'us', q: 1.0},
        {primary_tag: 'en', subtag: '*', q: 0.2}
      ]

      subject.new('en, en-us, *;q=0.8').list.map(&:language_tag).must_equal ['en-us', 'en', '*']
    end

    it "ignores the Accept-Language prefix" do
      subject.new('Accept-Language: en-us').list.map(&:language_tag).must_equal ['en-us']
    end

    it "accepts any language when the header is missing" do
      subject.new(nil).list.map(&:language_tag).must_equal ['*']
      subject.new(nil).negotiate('en-US').language_tag.must_equal 'en-us'
    end

    it "accepts no languages when the header is present and empty" do
      ['', " \t", 'Accept-Language:'].each do |header|
        assert_empty subject.new(header).list
        assert_nil subject.new(header).negotiate('en-US')
      end
    end

    it "parses a wildcard range" do
      subject.new('*').list.map(&:to_h).must_equal [
        {primary_tag: '*', subtag: '*', q: 1.0}
      ]
    end

    it "defaults quality to one" do
      subject.new('en-us').list.first.to_h.must_equal({primary_tag: 'en', subtag: 'us', q: 1.0})
    end

    it "uses the documented fallback quality for an invalid weight" do
      subject.new('en-us;q=x').list.first.to_h.must_equal({primary_tag: 'en', subtag: 'us', q: 0.001})
    end

    it "allows optional whitespace around ranges" do
      subject.new("\ten-us , en-gb\t").list.map(&:language_tag).must_equal ['en-us', 'en-gb']
    end

    it "retains every subtag and normalizes case" do
      subject.new('ZH-Hant-TW, en-US-omg;q=0.9').list.map(&:to_h).must_equal [
        {primary_tag: 'zh', subtag: 'hant-tw', q: 1.0},
        {primary_tag: 'en', subtag: 'us-omg', q: 0.9}
      ]
    end

    it "skips ranges outside the basic language-range grammar" do
      invalid = ['en-*', '*-US', 'en_US', '123', 'englishxx', 'en-123456789', 'en--US', 'en - US']
      subject.new((invalid + ['fr']).join(',')).list.map(&:language_tag).must_equal ['fr']
    end
  end

  describe "#to_s" do
    it "serializes basic language ranges without adding wildcards" do
      subject.new('en, zh-Hant-TW;q=0.9').to_s.must_equal 'en;q=1,zh-hant-tw;q=0.9'
    end
  end

  describe "negotiating supported languages" do
    it "returns the supported language rather than the matching range" do
      match = subject.new('en, *;q=0.8').negotiate('en-US')
      match.to_h.must_equal({primary_tag: 'en', subtag: 'us', q: 1.0})
    end

    it "returns a plain supported language without a synthetic wildcard" do
      subject.new('*').negotiate('en').language_tag.must_equal 'en'
    end

    it "matches script and region subtags case insensitively" do
      subject.new('zh-Hant').negotiate(['zh-Hans-TW', 'ZH-hant-TW']).language_tag.must_equal 'zh-hant-tw'
    end

    it "applies a more specific exclusion before its parent language range" do
      match = subject.new('zh, zh-Hant;q=0').negotiate(['zh-Hant-TW', 'zh-Hans-CN'])
      match.language_tag.must_equal 'zh-hans-cn'
    end

    it "uses the most specific matching range quality" do
      match = subject.new('en;q=1, en-US;q=0.1, fr;q=0.5').negotiate(['en-US', 'fr'])
      match.language_tag.must_equal 'fr'
    end

    it "rejects candidates outside a subtag boundary" do
      subject.new('en-US').accept?('en-USA').must_equal false
    end

    it "requires concrete supported language tags" do
      ['*', 'en-*', 'en_US', 'en;q=1'].each do |support|
        assert_raises(AcceptHeaders::InvalidSupportedValue) { subject.new('*').accept?(support) }
      end
      subject.new('*').accept?(nil).must_equal false
    end

    it "returns nil when no supported language matches" do
      _(subject.new('fr').negotiate('en')).must_be_nil
    end
  end
end
