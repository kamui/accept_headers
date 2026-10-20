require_relative "spec_helper"

class MalformedHeaderSpec < Minitest::Test
  def test_absent_accept_header_accepts_any_media_type
    result = AcceptHeaders::MediaType::Negotiator.new(nil).negotiate('text/html')

    assert_equal 'text/html', result.media_range
  end

  def test_present_empty_accept_header_accepts_no_media_types
    ['', " \t", 'Accept:'].each do |header|
      negotiator = AcceptHeaders::MediaType::Negotiator.new(header)

      assert_empty negotiator.list
      assert_nil negotiator.negotiate('text/html')
    end
  end

  def test_unqualified_media_types_are_skipped_without_raising
    negotiator = AcceptHeaders::MediaType::Negotiator.new('nonsense, text/html')

    assert_equal [{ type: 'text', subtype: 'html', q: 1.0, extensions: {} }], negotiator.list.map(&:to_h)
  end

  def test_invalidly_tagged_token_bytes_are_skipped_by_each_negotiator
    quality_negotiators.each do |negotiator, valid_token|
      invalid_token = "\xFF".freeze
      assert_empty negotiator.new(invalid_token).list

      header = "#{invalid_token},#{valid_token}"
      assert_equal negotiator.new(valid_token).list.map(&:to_h), negotiator.new(header).list.map(&:to_h)
      assert_equal Encoding::UTF_8, invalid_token.encoding
      refute invalid_token.valid_encoding?
    end
  end

  def test_quoted_obs_text_bytes_are_preserved_and_round_trip
    value = (0x80..0xFF).to_a.pack('C*')
    header = ('text/html;note="'.b + value + '"').force_encoding('UTF-8')
    item = AcceptHeaders::MediaType::Negotiator.new(header).list.first

    assert_equal value, item.extensions['note']
    assert_equal Encoding::ASCII_8BIT, item.extensions['note'].encoding
    assert_equal item.to_h, AcceptHeaders::MediaType::Negotiator.new(item.to_s).list.first.to_h
  end

  def test_valid_utf8_quoted_values_retain_their_encoding_and_round_trip
    value = "日本語; café"
    item = AcceptHeaders::MediaType::Negotiator.new("text/html;note=\"#{value}\"").list.first

    assert_equal value, item.extensions['note']
    assert_equal Encoding::UTF_8, item.extensions['note'].encoding
    assert_equal item.to_h, AcceptHeaders::MediaType::Negotiator.new(item.to_s).list.first.to_h
  end

  def test_invalid_media_ranges_do_not_match_partial_lines_or_non_token_characters
    ['*/json', 'text/html/extra', 'text/ht{ml}', 'text/ht\\ml', "text/html\nnonsense", 'text /html'].each do |range|
      assert_empty AcceptHeaders::MediaType::Negotiator.new(range).list, range
    end
  end

  def test_media_ranges_accept_http_token_characters_and_supported_wildcards
    ['application/x_example+json', 'application/problem+json', 'image/avif', 'text/*', '*/*', '*'].each do |range|
      assert_equal 1, AcceptHeaders::MediaType::Negotiator.new(range).list.size, range
    end
  end

  def test_quality_uses_the_complete_rfc_9110_qvalue_grammar
    values = {
      '0' => 0.0, '0.' => 0.0, '0.000' => 0.0,
      '0.123' => 0.123, '1' => 1.0, '1.' => 1.0, '1.000' => 1.0
    }

    quality_negotiators.each do |negotiator, value|
      values.each do |qvalue, expected|
        assert_equal expected, negotiator.new("#{value};q=#{qvalue}").list.first.q, "#{value};q=#{qvalue}"
      end
    end
  end

  def test_invalid_quality_preserves_the_documented_recovery_value
    ['', '.5', '+0.5', '01', '0.1234', '1.0000', '0.1e0', '"0.1"', '1.001', 'NaN', "0\nx"].each do |qvalue|
      quality_negotiators.each do |negotiator, value|
        assert_equal 0.001, negotiator.new("#{value};q=#{qvalue}").list.first.q, "#{value};q=#{qvalue}"
      end
    end
  end

  def test_quality_parameter_name_is_case_insensitive_and_exact
    quality_negotiators.each do |negotiator, value|
      assert_equal 0.4, negotiator.new("#{value};Q = 0.4").list.first.q
      assert_equal 1.0, negotiator.new("#{value};qs=0").list.first.q
    end
  end

  def test_quoted_parameter_contents_are_not_quality_parameters
    header = 'text/html;note="a;q=0;b"'

    assert_equal 1.0, AcceptHeaders::MediaType::Negotiator.new(header).list.first.q
  end

  def test_quality_after_escaped_quotes_is_still_parsed
    header = 'text/html;note="a\";q=0";q=0.8'

    assert_equal 0.8, AcceptHeaders::MediaType::Negotiator.new(header).list.first.q
  end

  def test_unterminated_quoted_parameters_are_skipped
    assert_empty AcceptHeaders::MediaType::Negotiator.new('text/html;note="a;q=0').list
  end

  private

  def quality_negotiators
    {
      AcceptHeaders::MediaType::Negotiator => 'text/html',
      AcceptHeaders::Encoding::Negotiator => 'gzip',
      AcceptHeaders::Language::Negotiator => 'en'
    }
  end
end
