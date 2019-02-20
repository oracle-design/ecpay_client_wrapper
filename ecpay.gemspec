# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecpay/version'

Gem::Specification.new do |spec|
  spec.name          = 'ecpay_client_wrapper'
  spec.version       = Ecpay::VERSION
  spec.authors       = ['Dylan']
  spec.email         = ['dylanmail0203@gmail.com']
  spec.summary       = '綠界（Ecpay）API 包裝'
  spec.description   = '綠界（Ecpay）API 包裝'
  spec.homepage      = 'https://github.com/oracle-design/ecpay_client_wrapper'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'json'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 12.3.1'
end
