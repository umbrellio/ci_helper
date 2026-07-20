# frozen_string_literal: true

require "ci_helper/tools/spec_timings_recorder"

describe CIHelper::Tools::SpecTimingsRecorder do
  let(:world) do
    instance_double(
      RSpec::Core::World,
      all_examples: [
        example_double("./spec/a_spec.rb[1:1]", 0.5),
        example_double("./spec/a_spec.rb[1:2]", 1.25),
        example_double("./spec/a_spec.rb[1:3]", nil), # loaded but filtered out on this node
      ],
    )
  end

  def example_double(example_id, run_time)
    execution_result = instance_double(RSpec::Core::Example::ExecutionResult, run_time:)
    instance_double(RSpec::Core::Example, id: example_id, execution_result:)
  end

  before { allow(RSpec).to receive(:world).and_return(world) }

  describe ".collect" do
    it "maps executed examples to run times, skipping loaded-but-unexecuted ones" do
      expect(described_class.collect).to eq(
        "./spec/a_spec.rb[1:1]" => 0.5,
        "./spec/a_spec.rb[1:2]" => 1.25,
      )
    end
  end

  describe ".install" do
    subject(:install) { described_class.install("coverage/spec_timings.json") }

    let(:config) { instance_double(RSpec::Core::Configuration) }

    before do
      allow(RSpec).to receive(:configure).and_yield(config)
      allow(File).to receive(:write)
    end

    # The recorder collects from an after(:suite) hook (runs even on failure) and never joins
    # the formatter list, so rspec keeps the suite's own formatters and its default output.
    it "writes the collected timings after the suite runs" do
      after_suite = nil
      allow(config).to receive(:after).with(:suite) { |&block| after_suite = block }

      install
      after_suite.call

      expect(File).to have_received(:write).with(
        "coverage/spec_timings.json",
        JSON.dump("./spec/a_spec.rb[1:1]" => 0.5, "./spec/a_spec.rb[1:2]" => 1.25),
      )
    end
  end
end
