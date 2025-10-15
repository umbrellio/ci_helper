# frozen_string_literal: true

require "ci_helper/commands/check_db_rollback"

describe CIHelper::Commands::CheckDBRollback do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  let(:options) { Hash[] }

  let(:expected_commands) do
    [
      "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
      "export RAILS_ENV=test && bundle exec rake db:rollback_new_migrations",
      "export RAILS_ENV=test && bundle exec rake db:migrate",
    ]
  end

  it "executes proper command and exits with success" do
    expect(command).to eq(0)
    expect(popen_executed_commands.size).to eq(3)
    expect(popen_executed_commands).to eq(expected_commands)
  end

  context "when with_clickhouse options" do
    let(:options) { Hash[with_clickhouse: "true"] }

    let(:expected_commands) do
      [
        "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
        "export RAILS_ENV=test && bundle exec rake db:rollback_new_migrations",
        "export RAILS_ENV=test && bundle exec rake db:migrate",
        "export RAILS_ENV=test && bundle exec rake ch:create ch:migrate",
        "export RAILS_ENV=test && bundle exec rake ch:rollback_new_migrations",
        "export RAILS_ENV=test && bundle exec rake ch:migrate",
      ]
    end

    it "executes proper command and exits with success" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(6)
      expect(popen_executed_commands).to eq(expected_commands)
    end
  end
end
