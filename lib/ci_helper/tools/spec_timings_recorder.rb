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
          config.after(:suite) { File.write(path, JSON.dump(SpecTimingsRecorder.collect)) }
        end
      end

      # A node runs only the example ids it was given, but rspec loads the whole file, so
      # all_examples also holds examples filtered out on this node; those never ran and have a
      # nil run_time. Skip them, otherwise they land as 0.0 and can overwrite real timings on merge.
      def self.collect
        RSpec.world.all_examples.each_with_object({}) do |example, timings|
          run_time = example.execution_result.run_time
          timings[example.id] = run_time.to_f if run_time
        end
      end
    end
  end
end
