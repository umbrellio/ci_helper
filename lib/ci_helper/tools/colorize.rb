# frozen_string_literal: true

module CIHelper
  module Tools
    module Colorize
      extend self

      def command(str)
        ColorizedString[ColorizedString["> "].green.bold + ColorizedString[str].blue.bold]
      end

      def info(str)
        ColorizedString[str].yellow
      end
    end
  end
end
