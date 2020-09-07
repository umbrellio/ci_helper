# frozen_string_literal: true

module CIHelper
  module Commands
    class Error < StandardError; end

    class BaseCommand
      class << self
        def call!(**options)
          new(**options).call
          0
        end

        # :nocov:
        def process_stdout
          @process_stdout ||= $stdout
        end
        # :nocov:
      end

      def initialize(**options)
        self.options = options
      end

      def execute_with_env(*commands)
        commands = ["export RAILS_ENV=#{env}", *commands] if env
        execute(*commands)
      end

      def execute(*commands)
        command = commands.join(" && ")

        process_stdout.puts(Tools::Colorize.command(command))

        Open3.popen2e(command) do |_stdin, stdout, thread|
          stdout.each_char { |char| process_stdout.print(char) }
          exit_code = thread.value.exitstatus

          fail!("Bad exit code #{exit_code} for command #{command.inspect}") unless exit_code.zero?
          0
        end
      end

      private

      attr_accessor :options

      def env; end

      def create_and_migrate_database!
        execute_with_env("bundle exec rake db:drop db:create db:migrate")
      end

      def fail!(message)
        raise Error, message
      end

      def plural_option(key)
        return [] unless options.key?(key)
        options[key].split(",")
      end

      def path
        @path ||= Pathname.pwd
      end

      def process_stdout
        self.class.process_stdout
      end
    end
  end
end
