# frozen_string_literal: true

require "bundler/setup"
require "simplecov"

require "bundler/setup"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
])

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
