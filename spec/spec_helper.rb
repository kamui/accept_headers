require "minitest/autorun"
require "minitest/focus"
require "codeclimate-test-reporter"
require "simplecov"
require "awesome_print"
require "pry"

CodeClimate::TestReporter.configure do |config|
  config.logger.level = Logger::WARN
end

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
  ]
end

require_relative "../lib/accept_headers"
