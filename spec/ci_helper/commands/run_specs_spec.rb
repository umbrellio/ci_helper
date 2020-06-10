# frozen_string_literal: true

describe CIHelper::Commands::RunSpecs do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  before { allow(Pathname).to receive(:pwd).and_return(mocked_pathname) }

  let(:options) { Hash[] }

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
      "bundle exec rspec cool_path_1 cool_path_0",
      "mv coverage/.resultset.json coverage/resultset.1.json",
    ]
  end

  it "executes command and exits with success" do
    expect(command).to eq(0)
    expect(popen_executed_commands.size).to eq(3)
    expect(popen_executed_commands).to eq(expected_commands)
  end

  context "with indexes in options" do
    let(:options) { Hash[node_index: "2", node_total: "2"] }

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
end
