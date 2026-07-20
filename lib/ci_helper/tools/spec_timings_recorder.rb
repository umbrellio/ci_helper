# frozen_string_literal: true

require "json"

module CIHelper
  module Tools
    # Records each example's run time to a flat JSON map ({ "./spec/a_spec.rb[1:1]" => 0.42 }),
    # the format RunSpecs consumes via --timings-file. RunSpecs wires it in through rspec's
    # --require. It collects timings from an after(:suite) hook, so it writes even when examples
    # fail; and, unlike a formatter, it never joins the formatter list, so rspec still installs
    # the suite's own formatters — including its default progress formatter when none is set.
    module SpecTimingsRecorder
      def self.install(path)
        RSpec.configure do |config|
          config.after(:suite) do
            timings = RSpec.world.all_examples.to_h do |example|
              [example.id, example.execution_result.run_time.to_f]
            end
            File.write(path, JSON.dump(timings))
          end
        end
      end
    end
  end
end
