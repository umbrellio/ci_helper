# frozen_string_literal: true

require "ci_helper/commands/check_db_development"

describe CIHelper::Commands::CheckDBDevelopment do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  let(:options) { Hash[] }

  let(:expected_commands) do
    [
      "export RAILS_ENV=development && bundle exec rake db:drop db:create db:migrate",
      "bundle exec rake db:seed",
    ]
  end

  it "executes proper command and exits with success" do
    expect(command).to eq(0)
    expect(popen_executed_commands.size).to eq(2)
    expect(popen_executed_commands).to eq(expected_commands)
  end

  context "when with_clickhouse options" do
    let(:options) { Hash[with_clickhouse: "true"] }

    let(:expected_commands) do
      [
        "export RAILS_ENV=development && bundle exec rake db:drop db:create db:migrate",
        "bundle exec rake db:seed",
        "export RAILS_ENV=development && bundle exec rake ch:create ch:migrate",
      ]
    end

    it "executes proper command and exits with success" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(3)
      expect(popen_executed_commands).to eq(expected_commands)
    end
  end
end
