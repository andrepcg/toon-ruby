# frozen_string_literal: true

require_relative 'lib/toon/version'

Gem::Specification.new do |spec|
  spec.name          = 'toon-ruby'
  spec.version       = Toon::VERSION
  spec.authors       = ['André Perdigão']
  spec.email         = ['andrepcg@gmail.com']

  spec.summary       = 'Token-Oriented Object Notation – a token-efficient JSON alternative for LLM prompts'
  spec.description   = 'TOON is a compact, human-readable format designed for passing structured data to Large Language Models with significantly reduced token usage.'
  spec.homepage      = 'https://github.com/andrepcg/toon-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/andrepcg/toon-ruby'

  spec.files = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
end
