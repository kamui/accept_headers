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

  def test_multibyte_headers_decode_quoted_pairs_as_http_bytes
    {
      [0x95, 0x5c, 0x5c] => [0x95, 0x5c],
      [0x95, 0x5c, 0x5c, 0x61] => [0x95, 0x5c, 0x61],
      [0x95, 0x5c, 0x61] => [0x95, 0x61],
      [0x95, 0x5c, 0x22, 0x61] => [0x95, 0x22, 0x61]
    }.each do |bytes, expected|
      wire = 'text/plain;note="'.b + bytes.pack('C*') + '";q=0.8,application/json;q=0.5'
      header = wire.dup.force_encoding('Shift_JIS').freeze
      assert header.valid_encoding?
      binary = AcceptHeaders::MediaType::Negotiator.new(wire)
      tagged = AcceptHeaders::MediaType::Negotiator.new(header)

      assert_equal binary.list.map(&:media_range), tagged.list.map(&:media_range)
      assert_equal binary.list.first.extensions['note'].bytes, tagged.list.first.extensions['note'].bytes
      assert_equal expected, tagged.list.first.extensions['note'].bytes
      assert_equal [0.8, 0.5], tagged.list.map(&:q)
      [wire.split(';q=').first, 'text/plain;note="other"', 'application/json'].each do |offer|
        assert_equal binary.accept?(offer), tagged.accept?(offer)
        assert_equal [binary.negotiate(offer)&.content_type&.bytes], [tagged.negotiate(offer)&.content_type&.bytes]
      end
      assert_equal wire.bytes, header.bytes
      assert_equal Encoding::Shift_JIS, header.encoding
    end
  end

  def test_multibyte_headers_reject_unterminated_http_quoted_pairs
    ['"', '",application/json'].each do |suffix|
      wire = 'text/plain;note="'.b + [0x95, 0x5c].pack('C*') + suffix
      header = wire.dup.force_encoding('Shift_JIS').freeze
      assert header.valid_encoding?

      [wire, header].each do |input|
        matcher = AcceptHeaders::MediaType::Negotiator.new(input)
        assert_empty matcher.list
        refute matcher.accept?('application/json')
        assert_nil matcher.negotiate('text/plain')
      end
      assert_equal wire.bytes, header.bytes
    end
  end

  def test_utf8_header_quoted_pairs_preserve_values_and_encoding
    header = 'text/plain;note="日本語; café\\"x\\\\y";q=0.8'.freeze
    tagged = AcceptHeaders::MediaType::Negotiator.new(header)
    binary = AcceptHeaders::MediaType::Negotiator.new(header.b)
    item = tagged.list.first

    assert_equal '日本語; café"x\\y', item.extensions['note']
    assert_equal Encoding::UTF_8, item.extensions['note'].encoding
    assert_equal 0.8, item.q
    assert_equal binary.list.first.extensions['note'].bytes, item.extensions['note'].bytes
    assert_equal item.to_h, AcceptHeaders::MediaType::Negotiator.new(item.to_s).list.first.to_h
    assert_equal item.content_type, tagged.negotiate(item.content_type).content_type
    assert_equal Encoding::UTF_8, header.encoding
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
