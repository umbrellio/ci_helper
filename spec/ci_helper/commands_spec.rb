# frozen_string_literal: true

describe CIHelper::Commands do
  include_context "commands context"

  let(:class_without_env) do
    Class.new(described_class::BaseCommand) do
      def call
        execute_with_env("ls")
      end
    end
  end

  it "skips exporting of env variable" do
    class_without_env.call!

    expect(popen_executed_commands.size).to eq(1)
    expect(popen_executed_commands.first).to eq("ls")
  end
end
