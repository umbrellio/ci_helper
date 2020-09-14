# frozen_string_literal: true

module CIHelper
  module Tools
    class Inflector < Delegator
      include Singleton

      # rubocop:disable Lint/MissingSuper
      def initialize
        @inflector = Dry::Inflector.new { |inflections| inflections.acronym "DB" }
      end
      # rubocop:enable Lint/MissingSuper

      def __getobj__
        @inflector
      end
    end
  end
end
