# frozen_string_literal: true

module CIHelper
  module Tools
    class Inflector < Delegator
      include Singleton

      def initialize
        @inflector = Dry::Inflector.new { |inflections| inflections.acronym "DB" }
      end

      def __getobj__
        @inflector
      end
    end
  end
end
