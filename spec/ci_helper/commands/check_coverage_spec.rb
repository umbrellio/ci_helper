# frozen_string_literal: true

require "ci_helper/commands/check_coverage"

describe CIHelper::Commands::CheckCoverage do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  before { allow(SimpleCov).to receive(:collate) { |paths| collate_args << paths } }
  before { allow(Pathname).to receive(:pwd).and_return(mocked_pathname) }

  let(:collate_args) { [] }
  let(:options) { Hash[split_resultset: "true"] }

  let(:mocked_pathname) do
    instance_double(Pathname).tap do |pathname|
      allow(pathname).to receive(:glob).and_return(array_of_pathnames)
      allow(pathname).to receive(:join).and_return(pathname_for_join)
    end
  end
  let(:array_of_pathnames) { Object.new }
  let(:pathname_for_join) { Object.new }

  it "executes command and exits with success" do
    expect(command).to eq(0)
    expect(collate_args.size).to eq(1)
    expect(collate_args.first).to eq(array_of_pathnames)
  end

  context "without split resultset" do
    let(:options) { Hash[] }

    it "executes collate with default path for resultset" do
      expect(command).to eq(0)
      expect(collate_args.size).to eq(1)
      expect(collate_args.first).to be_an_instance_of(Array)
      expect(collate_args.first.first).to eq(pathname_for_join)
    end
  end
end
