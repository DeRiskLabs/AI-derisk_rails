# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = 'ai-derisk_rails'
  spec.version     = '0.1.0'
  spec.authors     = ['DeriskLabs']
  spec.email       = ['engineering@derisklabs.com']

  spec.summary     = 'General Rails skills for AI coding agents.'
  spec.description = 'The derisk_rails skill collection: SKILL.md documents covering Rails ' \
                     'authoring and testing conventions. Data-only gem; nothing to require.'
  spec.homepage    = 'https://github.com/DeriskLabs/AI-derisk_rails'
  spec.license     = 'MIT'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'rubygems_mfa_required' => 'true',
  }

  spec.files = Dir['INDEX.md', 'GEMINI.md', 'LICENSE.txt', '*/**/*'].select { |f| File.file?(f) }

  spec.require_paths = ['.']

  spec.add_dependency 'ai-derisk_ruby', '~> 0.1'
end
