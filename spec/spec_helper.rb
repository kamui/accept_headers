require "simplecov"

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
  ]
  add_filter 'spec/'
end

require "minitest/autorun"
require "minitest/focus"
require "awesome_print"
require "pry"

require_relative "../lib/accept_headers"

INVALID_FLOAT_PATTERN = /\Ainvalid \w+ for Float(?:\(\)\: |\z)/

class Minitest::Spec
  def chrome
    {
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    }
  end

  def firefox
    {
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }
  end

  def safari
    {
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }
  end

  def ie
    {
      accept: 'text/html, application/xhtml+xml, */*'
    }
  end

  def all_browsers
    [chrome, firefox, safari, ie]
  end
end
