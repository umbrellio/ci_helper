# frozen_string_literal: true

require "ci_helper/tools/rspec_timings_formatter"

describe CIHelper::Tools::RSpecTimingsFormatter do
  subject(:formatter) { described_class.new(output) }

  let(:output) { StringIO.new }
  let(:summary) do
    instance_double(
      RSpec::Core::Notifications::SummaryNotification,
      examples: [
        example_double("./spec/a_spec.rb[1:1]", 0.5),
        example_double("./spec/b_spec.rb[1:2]", 1.25),
      ],
    )
  end

  def example_double(example_id, run_time)
    execution_result = instance_double(RSpec::Core::Example::ExecutionResult, run_time:)
    instance_double(RSpec::Core::Example, id: example_id, execution_result:)
  end

  it "writes a flat map of example ids to run times" do
    formatter.dump_summary(summary)
    expect(JSON.parse(output.string)).to eq(
      "./spec/a_spec.rb[1:1]" => 0.5,
      "./spec/b_spec.rb[1:2]" => 1.25,
    )
  end
end
