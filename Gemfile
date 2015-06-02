source "https://rubygems.org"

# Specify your gem's dependencies in accept_headers.gemspec
gemspec

group :test do
  gem "minitest-focus"
  gem "codeclimate-test-reporter", require: false
  gem "simplecov", require: false
end

group :development, :test do
  gem "pry"
  gem "awesome_print"
  gem "rack-test"
end
