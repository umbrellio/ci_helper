# frozen_string_literal: true

require "json"
require "tmpdir"

module CIHelper
  module Commands
    class RunSpecs < BaseCommand
      def call
        return if all_spec_files.empty?

        create_and_migrate_database! if with_database?
        create_and_migrate_clickhouse_database! if with_clickhouse?

        specs_to_run = job_count == 1 ? job_files : job_examples
        return 0 if specs_to_run.empty?

        execute("bundle exec rspec #{Shellwords.join(specs_to_run)}")
        return 0 unless split_resultset?

        execute("mv coverage/.resultset.json coverage/resultset.#{job_index}.json")
      end

      private

      def env
        :test
      end

      def all_spec_files
        @all_spec_files ||= path.glob("spec/**/*_spec.rb")
      end

      def job_files
        heavy_files, std_files = all_spec_files.partition { |f| heavy?(relative(f)) }
        sorted_std = std_files.map { |f| [f.size, relative(f)] }.sort.map(&:last)
        distribute(sorted_std + heavy_files)
      end

      def job_examples
        heavy, std = example_ids.partition do |id|
          heavy?(id.split("[", 2).first.delete_prefix("./"))
        end
        distribute(std.sort + heavy.sort)
      end

      def example_ids
        Dir.mktmpdir do |dir|
          output_file = File.join(dir, "rspec_examples.json")
          execute("bundle exec rspec --dry-run --format=json " \
                  "--out #{Shellwords.escape(output_file)}")
          JSON.parse(File.read(output_file)).fetch("examples").map { |e| e.fetch("id") }
        end
      end

      def distribute(items)
        items.reverse.select.with_index do |_item, index|
          (index % job_count) == (job_index - 1)
        end
      end

      def heavy?(relative_path)
        heavy_specs_paths.any? { |pattern| File.fnmatch?(pattern, relative_path) }
      end

      def relative(file)
        file.relative_path_from(path).to_s
      end

      def heavy_specs_paths
        @heavy_specs_paths ||=
          begin
            File.readlines("spec/heavy_specs.yml", chomp: true)
          rescue
            []
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

      def with_clickhouse?
        boolean_option(:with_clickhouse)
      end

      def split_resultset?
        boolean_option(:split_resultset)
      end
    end
  end
end
