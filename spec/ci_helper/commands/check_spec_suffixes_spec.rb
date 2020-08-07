# frozen_string_literal: true

require "tempfile"
require "ci_helper/commands/check_spec_suffixes"

describe CIHelper::Commands::CheckSpecSuffixes do
  include_context "commands context"

  subject(:command) { described_class.call!(**options) }

  let(:options) { Hash[] }

  specify { expect(command).to eq(0) }

  context "with extra paths" do
    let(:options) { Hash[extra_paths: "spec/*.rb"] }

    specify do
      expect { command }.to raise_error(/specs without _spec suffix/)
    end
  end

  context "when there is a spec file without _spec suffix" do
    after { temp_file.unlink }

    let!(:temp_file) { Tempfile.new(%w[kek_test .rb], "spec/ci_helper/") }

    specify do
      expect { command }.to raise_error(%r{specs without _spec suffix: spec/ci_helper/kek_test})
    end

    context "support file" do
      let!(:temp_file) { Tempfile.new(%w[kek_support_file .rb], "spec/support/") }

      specify { expect(command).to eq(0) }
    end

    context "context file" do
      let!(:temp_file) { Tempfile.new(%w[kek context.rb], "spec/ci_helper/") }

      specify { expect(command).to eq(0) }
    end

    context "with ignored paths" do
      let(:options) { Hash[ignored_paths: "spec/ci_helper/*.rb"] }

      specify { expect(command).to eq(0) }
    end
  end
end
