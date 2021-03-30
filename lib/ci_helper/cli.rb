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
      args
        .slice_when { |_el_before, el_after| el_after.start_with?("--") }
        .each_with_object({}) do |commands, options|
          key = Tools::Inflector.instance.underscore(commands.shift.split("--").last)
          raise "Invalid options" if key.empty?
          value = commands.size <= 1 ? commands.first : commands
          options[key.to_sym] = value || ""
        end
    end

    def perform_command!
      command_class.call!(**options).to_i
    rescue CIHelper::Commands::Error => error
      raise Error, error.message
    end
  end
end
