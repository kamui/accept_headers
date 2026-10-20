require_relative "spec_helper"

describe "Negotiation exclusions" do
  it "rejects an explicitly excluded media type despite an acceptable wildcard" do
    negotiator = AcceptHeaders::MediaType::Negotiator.new('text/html;q=0, */*;q=1')

    negotiator.negotiate('text/html').must_be_nil
    negotiator.accept?('text/html').must_equal false
    negotiator.negotiate(['text/html', 'application/json']).media_range.must_equal 'application/json'
  end

  it "allows an explicit media type to override a wildcard exclusion" do
    negotiator = AcceptHeaders::MediaType::Negotiator.new('*/*;q=0, text/html;q=1')

    negotiator.negotiate('text/html').media_range.must_equal 'text/html'
    negotiator.accept?('application/json').must_equal false
  end

  it "rejects an explicitly excluded encoding despite an acceptable wildcard" do
    negotiator = AcceptHeaders::Encoding::Negotiator.new('gzip;q=0, *;q=1')

    negotiator.negotiate('gzip').must_be_nil
    negotiator.accept?('gzip').must_equal false
    negotiator.negotiate(['gzip', 'br']).encoding.must_equal 'br'
  end

  it "allows an explicit encoding to override a wildcard exclusion" do
    negotiator = AcceptHeaders::Encoding::Negotiator.new('*;q=0, gzip;q=1')

    negotiator.negotiate('gzip').encoding.must_equal 'gzip'
    negotiator.accept?('br').must_equal false
  end

  it "rejects an explicitly excluded language despite an acceptable wildcard" do
    negotiator = AcceptHeaders::Language::Negotiator.new('en-us;q=0, *;q=1')

    negotiator.negotiate('en-us').must_be_nil
    negotiator.accept?('en-us').must_equal false
    negotiator.negotiate(['en-us', 'fr-ca']).language_tag.must_equal 'fr-ca'
  end

  it "allows an explicit language to override a wildcard exclusion" do
    negotiator = AcceptHeaders::Language::Negotiator.new('*;q=0, en-us;q=1')

    negotiator.negotiate('en-us').language_tag.must_equal 'en-us'
    negotiator.accept?('fr-ca').must_equal false
  end

  it "allows a regional language to override a broader language exclusion" do
    negotiator = AcceptHeaders::Language::Negotiator.new('en;q=0, en-us;q=1')

    negotiator.negotiate('en-us').language_tag.must_equal 'en-us'
    negotiator.accept?('en-gb').must_equal false
  end

  it "rejects a regional language despite an acceptable broader language" do
    negotiator = AcceptHeaders::Language::Negotiator.new('en-us;q=0, en;q=1')

    negotiator.negotiate('en-us').must_be_nil
    negotiator.negotiate(['en-us', 'en-gb']).language_tag.must_equal 'en-gb'
  end
end
