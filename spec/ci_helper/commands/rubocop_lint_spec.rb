# frozen_string_literal: true

describe CIHelper::Commands::RubocopLint do
  include_context "commands context"

  subject(:command) { described_class.call! }

  it "executes command and exits with success" do
    expect(command).to eq(0)
    expect(popen_executed_commands.size).to eq(1)
    expect(popen_executed_commands.first).to eq("bundle exec rubocop")
  end
end
