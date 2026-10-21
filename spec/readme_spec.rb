require_relative "spec_helper"
require "rack/builder"
require "rack/lint"
require "rack/mock"

class ReadmeSpec < Minitest::Test
  def test_documented_negotiation_results
    context = binding
    examples.each do |example|
      next if example.start_with?("gem ") || example.include?('use AcceptHeaders::Middleware')
      source = +""
      example.each_line do |line|
        if (expectation = /\A# => (.*)/.match(line))
          expected = eval(expectation[1], context, readme_path)
          actual = eval(source, context, readme_path)
          if expected.nil?
            assert_nil actual, source
          else
            assert_equal expected, actual, source
          end
          source.clear
        else
          source << line
        end
      end
      eval(source, context, readme_path) unless source.strip.empty?
    end
  end

  def test_rack_example_selects_supported_responses_and_honors_rejections
    source = examples.find { |example| example.include?('use AcceptHeaders::Middleware') }
    refute_nil source
    builder = Rack::Builder.new
    builder.instance_eval(source, readme_path)
    request = Rack::MockRequest.new(Rack::Lint.new(builder.to_app))

    response = request.get('/', 'HTTP_ACCEPT' => 'application/json', 'HTTP_ACCEPT_LANGUAGE' => 'en-GB')
    assert_equal 200, response.status
    assert_equal 'application/json;version=2', response['content-type']
    assert_equal 'en-gb', response['content-language']
    assert_equal '{"message":"Hello"}', response.body
    assert_nil response['content-encoding']
    assert_equal 'Accept, Accept-Encoding, Accept-Language', response['vary']

    [
      { 'HTTP_ACCEPT' => 'application/xml' },
      { 'HTTP_ACCEPT' => 'application/json;version=1' },
      { 'HTTP_ACCEPT_ENCODING' => 'identity;q=0' },
      { 'HTTP_ACCEPT_LANGUAGE' => 'fr' }
    ].each do |headers|
      rejected = request.get('/', headers)
      assert_equal 406, rejected.status, headers.inspect
      assert_equal 'Not acceptable', rejected.body
      assert_equal 'Accept, Accept-Encoding, Accept-Language', rejected['vary']
    end
  end

  private

  def readme_path
    File.expand_path('../README.md', __dir__)
  end

  def examples
    File.read(readme_path).scan(/```ruby\n(.*?)```/m).flatten
  end
end
