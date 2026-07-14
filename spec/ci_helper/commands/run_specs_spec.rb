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
        allow(pathname).to receive_messages(size: 1, relative_path_from: "cool_path_#{i}")
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

    let(:dry_run_json) do
      JSON.dump(examples: [
        { id: "./cool_path_0[1:1]" },
        { id: "./cool_path_0[1:2]" },
        { id: "./cool_path_1[1:1]" },
        { id: "./cool_path_1[1:2]" },
      ])
    end
    let(:expected_commands) do
      [
        "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
        "bundle exec rspec --dry-run --format=json " \
        "--out /tmp/ci_helper_test/rspec_examples.json",
        "bundle exec rspec ./cool_path_1\\[1:1\\] ./cool_path_0\\[1:1\\]",
        "mv coverage/.resultset.json coverage/resultset.2.json",
      ]
    end

    before do
      allow(Dir).to receive(:mktmpdir).and_wrap_original do |_original, &block|
        block.call("/tmp/ci_helper_test")
      end
      allow(File).to receive(:read)
        .with("/tmp/ci_helper_test/rspec_examples.json").and_return(dry_run_json)
    end

    it "splits examples properly" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(4)
      expect(popen_executed_commands).to eq(expected_commands)
    end

    context "with heavy specs" do
      before do
        allow(File).to receive(:readlines)
          .with("spec/heavy_specs.yml", chomp: true).and_return(["cool_path_0"])
      end

      let(:expected_commands) do
        [
          "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
          "bundle exec rspec --dry-run --format=json " \
          "--out /tmp/ci_helper_test/rspec_examples.json",
          "bundle exec rspec ./cool_path_0\\[1:1\\] ./cool_path_1\\[1:1\\]",
          "mv coverage/.resultset.json coverage/resultset.2.json",
        ]
      end

      it "back-loads heavy examples" do
        expect(command).to eq(0)
        expect(popen_executed_commands).to eq(expected_commands)
      end
    end

    context "when this node gets no examples" do
      let(:dry_run_json) { JSON.dump(examples: []) }

      let(:expected_commands) do
        [
          "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
          "bundle exec rspec --dry-run --format=json " \
          "--out /tmp/ci_helper_test/rspec_examples.json",
        ]
      end

      it "exits successfully without running rspec" do
        expect(command).to eq(0)
        expect(popen_executed_commands).to eq(expected_commands)
      end
    end

    context "with a timings file" do
      let(:options) do
        {
          split_resultset: "true", with_database: "true", node_index: "2", node_total: "2",
          timings_file: "spec_timings.json"
        }
      end
      let(:expected_commands) do
        [
          "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
          "bundle exec rspec --dry-run --format=json " \
          "--out /tmp/ci_helper_test/rspec_examples.json",
          "bundle exec rspec ./cool_path_0\\[1:2\\] ./cool_path_1",
          "mv coverage/.resultset.json coverage/resultset.2.json",
        ]
      end

      # cool_path_0 totals 45s (> 30s threshold) and is split by example;
      # cool_path_1[1:2] is absent and gets the median weight (5.0), so
      # cool_path_1 totals 6s and stays whole. LPT: node 1 <- [1:1] (40),
      # node 2 <- cool_path_1 (6) and cool_path_0[1:2] (5).
      let(:timings_json) do
        JSON.dump(
          "./cool_path_0[1:1]" => 40.0,
          "./cool_path_0[1:2]" => 5.0,
          "./cool_path_1[1:1]" => 1.0,
        )
      end

      before do
        allow(File).to receive(:read).with("spec_timings.json").and_return(timings_json)
      end

      it "packs by recorded timings, splitting heavy files by example" do
        expect(command).to eq(0)
        expect(popen_executed_commands).to eq(expected_commands)
      end

      context "when running the first node" do
        let(:options) { super().merge(node_index: "1") }

        let(:expected_commands) do
          [
            "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
            "bundle exec rspec --dry-run --format=json " \
            "--out /tmp/ci_helper_test/rspec_examples.json",
            "bundle exec rspec ./cool_path_0\\[1:1\\]",
            "mv coverage/.resultset.json coverage/resultset.1.json",
          ]
        end

        it "gets the complementary part of the partition" do
          expect(command).to eq(0)
          expect(popen_executed_commands).to eq(expected_commands)
        end
      end

      context "when the timings file is unreadable" do
        before do
          allow(File).to receive(:read).with("spec_timings.json").and_raise(Errno::ENOENT)
        end

        let(:expected_commands) do
          [
            "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
            "bundle exec rspec --dry-run --format=json " \
            "--out /tmp/ci_helper_test/rspec_examples.json",
            "bundle exec rspec ./cool_path_1\\[1:1\\] ./cool_path_0\\[1:1\\]",
            "mv coverage/.resultset.json coverage/resultset.2.json",
          ]
        end

        it "falls back to the count-based split" do
          expect(command).to eq(0)
          expect(popen_executed_commands).to eq(expected_commands)
        end
      end
    end

    context "with timings output" do
      let(:options) do
        {
          split_resultset: "true", with_database: "true", node_index: "2", node_total: "2",
          timings_out: "coverage/spec_timings.2.json"
        }
      end
      let(:expected_commands) do
        [
          "export RAILS_ENV=test && bundle exec rake db:drop db:create db:migrate",
          "bundle exec rspec --dry-run --format=json " \
          "--out /tmp/ci_helper_test/rspec_examples.json",
          "bundle exec rspec --format progress --format json --out coverage/spec_timings.2.json " \
          "./cool_path_1\\[1:1\\] ./cool_path_0\\[1:1\\]",
          "mv coverage/.resultset.json coverage/resultset.2.json",
        ]
      end

      let(:rspec_report_json) do
        JSON.dump(examples: [
          { id: "./cool_path_0[1:1]", run_time: 1.5 },
          { id: "./cool_path_1[1:1]", run_time: 0.25 },
        ])
      end

      before do
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:read)
          .with("coverage/spec_timings.2.json").and_return(rspec_report_json)
        allow(File).to receive(:write)
      end

      it "records a flat timings map of the run" do
        expect(command).to eq(0)
        expect(popen_executed_commands).to eq(expected_commands)
        expect(FileUtils).to have_received(:mkdir_p).with("coverage")
        expect(File).to have_received(:write).with(
          "coverage/spec_timings.2.json",
          JSON.dump("./cool_path_0[1:1]" => 1.5, "./cool_path_1[1:1]" => 0.25),
        )
      end
    end

    context "when dry-run exits with non-zero code" do
      let(:rspec_error_output) do
        "An error occurred while loading ./spec/broken_spec.rb.\n" \
          "LoadError: cannot load such file -- some_gem"
      end

      before do
        allow(Open3).to receive(:popen2e) do |cmd, &block|
          popen_executed_commands << cmd
          if cmd.include?("--dry-run")
            thread = instance_double(Thread, value: instance_double(Process::Status, exitstatus: 1))
            block.call(StringIO.new, StringIO.new(rspec_error_output), thread)
          else
            block.call(StringIO.new, StringIO.new("kek"), popen_thread)
          end
        end
      end

      it "fails with the rspec command output rather than the json file" do
        expect { command }.to raise_error(CIHelper::Commands::Error) do |error|
          expect(error.message).to include("RSpec dry-run failed:")
          expect(error.message).to include(rspec_error_output)
          expect(error.message).not_to include("Output file contents")
        end
      end
    end
  end

  context "without database and resultset splitting" do
    let(:options) { {} }

    let(:expected_commands) { ["bundle exec rspec cool_path_1 cool_path_0"] }

    it "performs proper commands" do
      expect(command).to eq(0)
      expect(popen_executed_commands.size).to eq(1)
      expect(popen_executed_commands).to eq(expected_commands)
    end
  end

  context "when spec folder is empty" do
    let(:array_of_pathnames) { [] }

    it "skips everything" do
      expect(command).to be_nil
      expect(popen_executed_commands).to be_empty
    end
  end
end
