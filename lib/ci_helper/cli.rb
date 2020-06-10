# frozen_string_literal: true

module CIHelper
  module CLI
    extend self

    class Error < StandardError; end

    def run!(args)
      self.args = args.dup
      prepare!
      perform_command!
    end

    private

    attr_accessor :args, :command_class, :options

    def prepare!
      self.command_class = Object.const_get("CIHelper::Commands::#{args.shift}")
      self.options = parse_options_from(args)
    end

    def parse_options_from(args)
      args.each_slice(2).with_object({}) do |args, options|
        key = args.first&.split("--")&.last&.tr("-", "_")
        value = args[1]
        raise Error, "Not valid options" if [key, value].any?(&:nil?)

        options[key.to_sym] = value
      end
    end

    def perform_command!
      command_class.call!(**options).to_i
    rescue CIHelper::Commands::Error => error
      raise Error, error.message
    end
  end
end
