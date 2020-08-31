# frozen_string_literal: true

require "bundler/setup"
require "simplecov"
require "simplecov-lcov"

require "bundler/setup"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.lcov_file_name = "lcov.info"
  c.output_directory = "coverage"
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter,
])

SimpleCov.minimum_coverage(100) if ENV["FULL_COVERAGE_CHECK"]

SimpleCov.start

require "ci_helper"

Dir[Pathname(__dir__).join("support/**/*")].sort.each { |x| require(x) }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
