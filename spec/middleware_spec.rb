require_relative "spec_helper"
require "accept_headers/middleware"
require "rack/test"

describe AcceptHeaders::Middleware do
  subject do
    AcceptHeaders::Middleware
  end

  def app(
    supported_media_types: ['application/json'],
    supported_encodings: ['identity'],
    supported_languages: ['en-US']
  )
    Rack::Builder.new do
      use AcceptHeaders::Middleware
      run ->(env) do
        matched_media_type = env["accept_headers.media_types"].negotiate(supported_media_types)
        matched_encoding = env["accept_headers.encodings"].negotiate(supported_encodings)
        matched_language = env["accept_headers.languages"].negotiate(supported_languages)
        headers = {
          'Content-Type' => matched_media_type ? matched_media_type.media_range : '',
          'Content-Encoding' => matched_encoding ? matched_encoding.encoding : '',
          'Content-Language' => matched_language ? matched_language.language_tag : '',
        }

        [ 200, headers, [ '' ] ]
      end
    end
  end

  def responds_with_content_type(accept, supported_media_types, expected_content_type)
    response = Rack::MockRequest.new(app(supported_media_types: supported_media_types)).get('/', { 'HTTP_ACCEPT' => accept } )
    response.headers['Content-Type'].must_equal expected_content_type
  end

  def responds_with_encoding(accept_encoding, supported_encodings, expected_encoding)
    response = Rack::MockRequest.new(app(supported_encodings: supported_encodings)).get('/', { 'HTTP_ACCEPT_ENCODING' => accept_encoding } )
    response.headers['Content-Encoding'].must_equal expected_encoding
  end

  def responds_with_languages(accept_language, supported_languages, expected_language)
    response = Rack::MockRequest.new(app(supported_languages: supported_languages)).get('/', { 'HTTP_ACCEPT_LANGUAGE' => accept_language } )
    response.headers['Content-Language'].must_equal expected_language
  end

  it "reads the accept header" do
    responds_with_content_type("application/json", ['application/json'], 'application/json')
    responds_with_content_type("application/json;q=0.9,*/*;q0.8", ['application/json'], 'application/json')
    responds_with_content_type("application/json/error", ['application/json'], '')
  end

  it "reads the accept encoding header" do
    responds_with_encoding("gzip,identity", ['gzip', 'identity'], 'gzip')
    responds_with_encoding("gzip;q=0.8,identity", ['gzip', 'identity'], 'identity')
    responds_with_encoding("gzip error", ['gzip'], '')
  end

  it "reads the accept language header" do
    responds_with_languages("en-us", ['en-us'], 'en-us')
    responds_with_languages("en-us;q=1,en-gb;q=0.9,en-*;q=0.8", ['en-us'], 'en-us')
    responds_with_languages("en/us", ['en-us'], '')
  end
end
