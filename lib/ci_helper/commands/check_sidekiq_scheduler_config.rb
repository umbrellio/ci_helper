# frozen_string_literal: true

require "yaml"

module CIHelper
  module Commands
    class CheckSidekiqSchedulerConfig < BaseCommand
      def call
        cmd = craft_jobs_const_get_cmd
        execute_with_rails_runner(cmd)
        0
      end

      private

      def execute_with_rails_runner(cmd)
        execute("bundle exec rails runner -e '#{cmd}'")
      end

      def craft_jobs_const_get_cmd
        "#{job_constants}.each { |x| Object.const_get(x) }"
      end

      def job_constants
        config.values.flat_map(&:keys).uniq!
      end

      def config
        @config ||= YAML.load_file(options[:config_path])
      end
    end
  end
end
