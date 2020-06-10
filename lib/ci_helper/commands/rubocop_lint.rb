# frozen_string_literal: true

module CIHelper
  module Commands
    class RubocopLint < BaseCommand
      def call
        execute("bundle exec rubocop")
      end
    end
  end
end
