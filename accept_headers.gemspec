# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'accept_headers/version'

Gem::Specification.new do |spec|
  spec.name          = "accept_headers"
  spec.version       = AcceptHeaders::VERSION
  spec.authors       = ["Jack Chu"]
  spec.email         = ["kamuigt@gmail.com"]
  spec.summary       = %q{A ruby library that parses and sorts http accept headers.}
  spec.description   = %q{A ruby library that parses and sorts http accept headers. Adheres to RFC 2616.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency "minitest", "~> 5.4"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
end
