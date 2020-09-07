# frozen_string_literal: true

module CIHelper
  module Commands
    class CheckCoverage < BaseCommand
      def call
        SimpleCov.collate(files)
      end

      private

      def files
        return path.glob("coverage/resultset.*.json") if split_resultset?

        [path.join("coverage/.resultset.json")]
      end

      def split_resultset?
        options[:split_resultset] == "true"
      end
    end
  end
end
