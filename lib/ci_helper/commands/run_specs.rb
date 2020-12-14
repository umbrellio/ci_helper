# frozen_string_literal: true

module CIHelper
  module Commands
    class RunSpecs < BaseCommand
      def call
        return if job_files.empty?

        create_and_migrate_database! if with_database?
        execute("bundle exec rspec #{Shellwords.join(job_files)}")
        return 0 unless split_resultset?

        execute("mv coverage/.resultset.json coverage/resultset.#{job_index}.json")
      end

      private

      def env
        :test
      end

      def job_files
        all_files = path.glob("spec/**/*_spec.rb")
        sorted_files =
          all_files.map { |x| [x.size, x.relative_path_from(path).to_s] }.sort.map(&:last)
        sorted_files.reverse.select.with_index do |_file, index|
          (index % job_count) == (job_index - 1)
        end
      end

      def job_index
        @job_index ||= options[:node_index]&.to_i || 1
      end

      def job_count
        @job_count ||= options[:node_total]&.to_i || 1
      end

      def with_database?
        boolean_option(:with_database)
      end

      def split_resultset?
        boolean_option(:split_resultset)
      end
    end
  end
end
