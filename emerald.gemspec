# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'emerald/version'

Gem::Specification.new do |spec|
  spec.name          = "emerald"
  spec.version       = Emerald::VERSION
  spec.authors       = ["Jiahao Li"]
  spec.email         = ["isundaylee.reg@gmail.com"]
  spec.summary       = %q{Gem for downloading music from various website. }
  spec.description   = %q{Gem for downloading music from various website. }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency     "nokogiri"
  spec.add_runtime_dependency     "taglib-ruby"
  spec.add_runtime_dependency     "ruby-pinyin"
end
