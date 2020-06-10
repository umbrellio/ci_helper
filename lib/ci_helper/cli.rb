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
      class_name = args.shift
      self.options = parse_options_from(args)
      require(Tools::Inflector.instance.underscore("ci_helper/commands/#{class_name}"))
      self.command_class = Commands.const_get(class_name)
    rescue LoadError => error
      raise Error, "Can't find command with path: #{error.path}"
    end

    def parse_options_from(args)
      args.each_slice(2).with_object({}) do |args, options|
        key = Tools::Inflector.instance.underscore(args.first.split("--").last)
        value = args[1] || ""
        raise Error, "Not valid options" if key.empty?

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
