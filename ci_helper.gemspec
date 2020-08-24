# frozen_string_literal: true

require_relative "lib/ci_helper/version"

Gem::Specification.new do |spec|
  spec.name          = "ci-helper"
  spec.version       = CIHelper::VERSION
  spec.authors       = ["JustAnotherDude"]
  spec.email         = ["vanyaz158@gmail.com"]

  spec.summary       = "Continuous Integration helpers for Ruby"
  spec.description   = "CIHelper is a gem with Continuous Integration helpers for Ruby"
  spec.homepage      = "https://github.com/umbrellio/ci_helper"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/umbrellio/ci_helper"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "colorize", "~> 0.8"
  spec.add_runtime_dependency "dry-inflector", "~> 0.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-config-umbrellio"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-lcov"
end
