# frozen_string_literal: true

require "simplecov"

module CIHelper
  module Commands
    class CheckCoverage < BaseCommand
      def call
        require(path.join(setup_file_path)) unless setup_file_path.nil?

        ::SimpleCov.collate(files)
        0
      end

      private

      def files
        return path.glob("coverage/resultset.*.json") if split_resultset?

        [path.join("coverage/.resultset.json")]
      end

      def split_resultset?
        boolean_option(:split_resultset)
      end

      def setup_file_path
        options[:setup_file_path]
      end
    end
  end
end
