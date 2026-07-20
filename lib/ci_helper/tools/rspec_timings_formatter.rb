# frozen_string_literal: true

require "json"
require "rspec/core/formatters/base_formatter"

module CIHelper
  module Tools
    # Records each example's run time as a flat JSON map ({ "./spec/a_spec.rb[1:1]" => 0.42 }),
    # the format RunSpecs consumes via --timings-file. RunSpecs registers it as an additional
    # formatter (via --require) so it never displaces the suite's own formatters, and it writes
    # on dump_summary, which RSpec runs even when examples fail.
    class RSpecTimingsFormatter < RSpec::Core::Formatters::BaseFormatter
      RSpec::Core::Formatters.register self, :dump_summary

      def dump_summary(summary)
        timings = summary.examples.to_h do |example|
          [example.id, example.execution_result.run_time.to_f]
        end
        output.write(JSON.dump(timings))
      end
    end
  end
end
