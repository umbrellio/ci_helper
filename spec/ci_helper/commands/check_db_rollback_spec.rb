# frozen_string_literal: true

describe CIHelper::Commands::CheckDBRollback do
  include_context "commands context"

  subject(:command) { described_class.call! }

  let(:expected_commands) do
    [
      "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
      "export RAILS_ENV=test && bundle exec rake db:rollback_new_migrations",
      "export RAILS_ENV=test && bundle exec rake db:migrate",
    ]
  end

  it "executes proper command and exists with success" do
    expect(command).to eq(0)
    expect(popen_executed_commands.size).to eq(3)
    expect(popen_executed_commands).to eq(expected_commands)
  end
end
