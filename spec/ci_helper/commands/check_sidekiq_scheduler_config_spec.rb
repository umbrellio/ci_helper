# frozen_string_literal: true

require "tempfile"
require "ci_helper/commands/check_sidekiq_scheduler_config"

describe CIHelper::Commands::CheckSidekiqSchedulerConfig do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  before { File.write(config.path, schedule) }
  after { config.unlink }

  let(:config) { Tempfile.new("sidekiq_scheduler.yml", "spec/support/") }
  let(:schedule) do
    <<~YAML
      defaults: &defaults
        "Jobs::Kek":
          cron: "0 0 0 0 0"

      development: *defaults
      test:
        <<: *defaults
        "Jobs::Pek":
          cron: "0 0 0 0 0"
      staging: *defaults
      production: *defaults
    YAML
  end

  let(:options) { Hash[config_path: config.path] }

  let(:expected_commands) do
    [
      %(bundle exec rails runner '["Jobs::Kek", "Jobs::Pek"].each { |x| Object.const_get(x) }'),
    ]
  end

  it "executes proper rails runner commands" do
    expect(command).to eq(0)
    expect(popen_executed_commands).to eq(expected_commands)
  end

  context "with database" do
    let(:options) { Hash[config_path: config.path, with_database: "true"] }

    let(:expected_commands) do
      [
        %(export RAILS_ENV=development && bundle exec rake db:drop db:create db:migrate),
        %(bundle exec rails runner '["Jobs::Kek", "Jobs::Pek"].each { |x| Object.const_get(x) }'),
      ]
    end

    it "executes proper rails runner commands" do
      expect(command).to eq(0)
      expect(popen_executed_commands).to eq(expected_commands)
    end
  end

  context "empty schedule" do
    let(:schedule) do
      <<~YAML
        defaults: &defaults
        development: *defaults
        test: *defaults
        staging: *defaults
        production: *defaults
      YAML
    end

    let(:expected_commands) { [] }

    it "executes proper rails runner commands" do
      expect(command).to eq(0)
      expect(popen_executed_commands).to eq(expected_commands)
    end
  end
end
