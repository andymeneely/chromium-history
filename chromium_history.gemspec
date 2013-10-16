# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chromium_history/version'

Gem::Specification.new do |spec|
  spec.name          = "chromium_history"
  spec.version       = ChromiumHistory::VERSION
  spec.authors       = ["Andy Meneely", 
  					    "Katherine Whitlock",
						"Shannon Trudeau",
						"Christopher Ketant",
						"Alberto Rodriguez",
						"Danielle Neuberger"]
  spec.description   = %q{Scripts for downloading, parsing, and analyzing the history of the Chromium project}
  spec.summary       = spec.description
  spec.homepage      = "http://www.se.rit.edu/~archeology/"
  spec.license       = ""

  #spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
