# frozen_string_literal: true

module CIHelper
end

require "colorized_string"
require "delegate"
require "dry/inflector"
require "open3"
require "pathname"
require "shellwords"
require "singleton"

require "ci_helper/cli"
require "ci_helper/commands"
require "ci_helper/tools/colorize"
require "ci_helper/tools/inflector"
require "ci_helper/version"

# :nocov:
require "ci_helper/railtie" if defined?(Rails)
# :nocov:
