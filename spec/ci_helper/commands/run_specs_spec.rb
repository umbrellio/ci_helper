# frozen_string_literal: true

require "ci_helper/commands/run_specs"

describe CIHelper::Commands::RunSpecs do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  before { allow(Pathname).to receive(:pwd).and_return(mocked_pathname) }

  let(:options) { Hash[split_resultset: "true", with_database: "true", with_clickhouse: "true"] }

  let(:mocked_pathname) do
    instance_double(Pathname).tap do |pathname|
      allow(pathname).to receive(:glob).and_return(array_of_pathnames)
    end
  end
  let(:array_of_pathnames) do
    Array.new(2) do |i|
      instance_double(Pathname).tap do |pathname|
        allow(pathname).to receive(:size).and_return(1)
        allow(pathname).to receive(:relative_path_from).and_return("cool_path_#{i}")
      end
    end
  end

  let(:expected_commands) do
    [
      "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
      "export RAILS_ENV=test && bundle exec rake ch:create ch:migrate",
      "bundle exec rspec cool_path_1 cool_path_0",
      "mv coverage/.resultset.json coverage/resultset.1.json",
    ]
  end

  it "executes command and exits with success" do
    expect(command).to eq(0)
    expect(popen_executed_commands.size).to eq(4)
    expect(popen_executed_commands).to eq(expected_commands)
  end

  context "with indexes in options" do
    let(:options) do
      { split_resultset: "true", with_database: "true", node_index: "2", node_total: "2" }
    end

    let(:expected_commands) do
      [
        "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
        "bundle exec rspec cool_path_0",
        "mv coverage/.resultset.json coverage/resultset.2.json",
      ]
    end

    it "splits files properly" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(3)
      expect(popen_executed_commands).to eq(expected_commands)
    end
  end

  context "without database and resultset splitting" do
    let(:options) { Hash[] }

    let(:expected_commands) { ["bundle exec rspec cool_path_1 cool_path_0"] }

    it "performs proper commands" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(1)
      expect(popen_executed_commands).to eq(expected_commands)
    end
  end
end
