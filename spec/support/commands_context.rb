# frozen_string_literal: true

shared_context "commands context" do
  before do
    allow(Open3).to receive(:popen2e) do |command, &block|
      popen_executed_commands << command
      block.call(StringIO.new, StringIO.new("kek"), popen_thread)
    end

    allow(CIHelper::Commands::BaseCommand).to receive(:process_stdout).and_return(stdout_io)
  end

  let(:popen_thread) { instance_double(Thread, value: process_value) }
  let(:process_value) { instance_double(Process::Status, exitstatus: process_value_exit_status) }
  let(:process_value_exit_status) { 0 }

  let(:popen_executed_commands) { [] }
  let(:stdout_io) { StringIO.new }
end
