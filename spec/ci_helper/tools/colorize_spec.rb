# frozen_string_literal: true

describe CIHelper::Tools::Colorize do
  it "methods returns ColorizedString class" do
    expect(described_class.command("kek")).to be_an_instance_of(ColorizedString)
    expect(described_class.info("kek")).to be_an_instance_of(ColorizedString)
  end
end
