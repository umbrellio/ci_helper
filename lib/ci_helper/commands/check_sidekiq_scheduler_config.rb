# frozen_string_literal: true

require "yaml"

module CIHelper
  module Commands
    class CheckSidekiqSchedulerConfig < BaseCommand
      def call
        return 0 if job_constants.empty?

        create_and_migrate_database! if with_database?
        cmd = craft_jobs_const_get_cmd
        execute_with_rails_runner(cmd)
        0
      end

      private

      def env
        :development
      end

      def execute_with_rails_runner(cmd)
        execute("bundle exec rails runner '#{cmd}'")
      end

      def craft_jobs_const_get_cmd
        "#{job_constants}.each { |x| Object.const_get(x) }"
      end

      def job_constants
        @job_constants ||= config.values.reject(&:nil?).flat_map(&:keys).uniq
      end

      def with_database?
        boolean_option(:with_database)
      end

      def config
        @config ||= YAML.load_file(options[:config_path])
      end
    end
  end
end
