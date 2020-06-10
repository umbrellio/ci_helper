# frozen_string_literal: true

describe CIHelper::CLI do
  include_context "commands context"

  subject(:client_response) { described_class.run!(args) }

  let(:args) { [command_class_name] }
  let(:command_class_name) { "BundlerAudit" }

  it "properly processes bundler audit" do
    expect(client_response).to eq(0)
    expect(popen_executed_commands.size).to eq(1)
    expect(popen_executed_commands.first).to eq("bundle exec bundler-audit check --update")
  end

  context "with additional options" do
    let(:args) { [command_class_name, "--ignored-advisories", "ignored-advisory"] }

    let(:expected_command) { "bundle exec bundler-audit check --update --ignore ignored-advisory" }

    it "properly parses this option" do
      expect(client_response).to eq(0)
      expect(popen_executed_commands.size).to eq(1)
      expect(popen_executed_commands.first).to eq(expected_command)
    end
  end

  context "with invalid args" do
    let(:args) { [command_class_name, ""] }

    it "raises error" do
      expect { described_class.run!(args) }.to raise_error("Not valid options")
    end
  end

  context "with last flag without value" do
    let(:args) { [command_class_name, "--ignored-advisories"] }

    let(:expected_command) { "bundle exec bundler-audit check --update" }

    it "executes audit without ignored advisories" do
      expect(client_response).to eq(0)
      expect(popen_executed_commands.size).to eq(1)
      expect(popen_executed_commands.first).to eq(expected_command)
    end
  end

  context "with bad thread exit code" do
    let(:process_value_exit_status) { 1 }
    let(:raised_error_message) do
      %(Bad exit code 1 for command "bundle exec bundler-audit check --update")
    end

    it "raises error with bad exit code" do
      expect { described_class.run!(args) }.to raise_error(raised_error_message)
    end
  end

  context "with not existed command" do
    let(:args) { ["BadCommand"] }

    let(:raised_error_message) { "Can't find command with path: ci_helper/commands/bad_command" }

    it "raises error" do
      expect { described_class.run!(args) }.to raise_error(raised_error_message)
    end
  end
end
