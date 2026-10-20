require "accept_headers/acceptable"

module AcceptHeaders
  class Language
    include Comparable
    include Acceptable

    attr_reader :primary_tag, :subtag

    def initialize(primary_tag = '*', subtag = nil, q: 1.0)
      self.primary_tag = primary_tag
      self.subtag = subtag
      self.q = q
    end

    def <=>(other)
      [q, specificity] <=> [other.q, other.specificity]
    end

    def primary_tag=(value)
      @primary_tag = value.strip.downcase
    end

    def subtag=(value)
      @subtag = if value.nil?
        '*'
      else
        value.strip.downcase
      end
    end

    def to_h
      {
        primary_tag: primary_tag,
        subtag: subtag,
        q: q
      }
    end

    def to_s
      qvalue = (q == 0 || q == 1) ? q.to_i : q
      "#{language_tag};q=#{qvalue}"
    end

    def language_tag
      subtag == '*' ? primary_tag : "#{primary_tag}-#{subtag}"
    end

    def specificity
      [primary_tag == '*' ? 0 : language_tag.split('-').length]
    end

    def match(language_tag_string)
      return false unless language_tag_string.is_a?(String)
      return false unless Negotiator::SUPPORTED_LANGUAGE_TAG_PATTERN.match?(language_tag_string)
      candidate = language_tag_string.downcase
      range = language_tag
      range == '*' || candidate == range || candidate.start_with?("#{range}-")
    end
  end
end
