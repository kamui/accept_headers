require_relative "spec_helper"

describe "acceptable value equality" do
  let(:values) do
    [
      AcceptHeaders::MediaType.new('text', 'html'),
      AcceptHeaders::Encoding.new('gzip'),
      AcceptHeaders::Language.new('en', 'us')
    ]
  end

  it "compares all normalized fields for values of the same class" do
    assert_equal AcceptHeaders::MediaType.new('text', 'html', extensions: { 'level' => '1' }),
      AcceptHeaders::MediaType.new('TEXT', 'HTML', extensions: { 'level' => '1' })
    assert_equal AcceptHeaders::Encoding.new('gzip'), AcceptHeaders::Encoding.new('GZIP')
    assert_equal AcceptHeaders::Language.new('en', 'us'), AcceptHeaders::Language.new('EN', 'US')
    values.each { |value| assert_equal value, value }
  end

  it "distinguishes different media types and parameters at the same preference rank" do
    refute_equal AcceptHeaders::MediaType.new('text', 'html'), AcceptHeaders::MediaType.new('text', 'plain')
    refute_equal AcceptHeaders::MediaType.new('text', 'plain'), AcceptHeaders::MediaType.new('application', 'plain')
    refute_equal AcceptHeaders::MediaType.new('text', 'html', extensions: { 'level' => '1' }),
      AcceptHeaders::MediaType.new('text', 'html', extensions: { 'level' => '2' })
    refute_equal AcceptHeaders::MediaType.new('text', 'html', extensions: { 'level' => '1' }),
      AcceptHeaders::MediaType.new('text', 'html', extensions: { 'version' => '1' })
  end

  it "distinguishes encodings and languages at the same preference rank" do
    refute_equal AcceptHeaders::Encoding.new('gzip'), AcceptHeaders::Encoding.new('compress')
    refute_equal AcceptHeaders::Language.new('en', 'us'), AcceptHeaders::Language.new('en', 'gb')
    refute_equal AcceptHeaders::Language.new('en', 'us'), AcceptHeaders::Language.new('fr', 'us')
  end

  it "includes quality in equality" do
    values.each do |value|
      different_quality = value.dup
      different_quality.q = 0.5
      refute_equal value, different_quality
      refute_equal different_quality, value
    end
  end

  it "returns false symmetrically for different classes and unrelated objects" do
    values.each do |value|
      (values.reject { |other| other.class == value.class } + [nil, Object.new, value.to_h]).each do |other|
        refute_equal value, other
        refute_equal other, value
      end
      subclass_value = Class.new(value.class).new
      value.to_h.each { |field, field_value| subclass_value.public_send("#{field}=", field_value) }
      refute_equal value, subclass_value
      refute_equal subclass_value, value
    end
  end

  it "keeps equal preference ranks sortable without making their values equal" do
    [
      [AcceptHeaders::MediaType.new('text', 'html'), AcceptHeaders::MediaType.new('text', 'plain')],
      [AcceptHeaders::Encoding.new('gzip'), AcceptHeaders::Encoding.new('compress')],
      [AcceptHeaders::Language.new('en', 'us'), AcceptHeaders::Language.new('en', 'gb')]
    ].each do |left, right|
      assert_equal 0, left <=> right
      assert_equal 0, right <=> left
      refute_equal left, right
      refute_equal right, left
      assert_equal [left.to_h, right.to_h], [left, right].sort.map(&:to_h)
    end
  end
end
