# frozen_string_literal: true

require "ci_helper/commands/bundler_audit"

describe CIHelper::Commands::BundlerAudit do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  let(:options) { Hash[] }

  it "executes proper command and exists with success" do
    expect(command).to eq(0)
    expect(popen_executed_commands.size).to eq(1)
    expect(popen_executed_commands.first).to eq("bundle exec bundler-audit check --update")
  end

  context "with error response from thread" do
    let(:process_value_exit_status) { 1 }

    it "fails with error" do
      expect { command }.to raise_error do |error|
        expect(error.message).to match(/Bad exit code 1 for command/)
      end
    end
  end

  context "with ignored advisories" do
    let(:options) { Hash[ignored_advisories: "kek,pek"] }

    let(:expected_command) { "bundle exec bundler-audit check --update --ignore kek pek" }

    it "executes audit with ignored advisories" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(1)
      expect(popen_executed_commands.first).to eq(expected_command)
    end
  end

  context "with empty ignored advisories" do
    let(:options) { Hash[ignored_advisories: ""] }

    it "executes command without ignore flag" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(1)
      expect(popen_executed_commands.first).to eq("bundle exec bundler-audit check --update")
    end
  end
end
