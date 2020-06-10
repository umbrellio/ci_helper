# frozen_string_literal: true

require "simplecov"

module CIHelper
  module Commands
    class CheckCoverage < BaseCommand
      def call
        results = process_results
        result = SimpleCov::ResultMerger.merge_results(*results)
        fail!("No coverage info found!") if result.total_lines.zero?

        result.format!
        SimpleCov::ResultProcessor.call(result)
      end

      private

      def process_results
        files = path.glob(result_set_mask)
        files.sort.map do |file_result|
          process_stdout.puts(pastel.blue("Processing #{file_result}"))
          data = JSON.parse(file_result.read)
          SimpleCov::Result.from_hash(data)
        end
      end

      def result_set_mask
        "coverage/resultset.*.json"
      end
    end
  end
end
