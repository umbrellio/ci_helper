# frozen_string_literal: true

require "fileutils"
require "json"
require "tmpdir"

module CIHelper
  module Commands
    class RunSpecs < BaseCommand
      DEFAULT_SPLIT_THRESHOLD = 30.0

      def call
        return if all_spec_files.empty?

        create_and_migrate_database! if with_database?
        create_and_migrate_clickhouse_database! if with_clickhouse?

        specs_to_run = job_count == 1 ? job_files : job_examples
        return 0 if specs_to_run.empty?

        FileUtils.mkdir_p(File.dirname(timings_out)) if timings_out
        execute("bundle exec rspec #{Shellwords.join(timings_out_arguments + specs_to_run)}")
        write_flat_timings! if timings_out
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
        timings.empty? ? counted_job_examples : timed_job_examples
      end

      def counted_job_examples
        heavy, std = example_ids.partition do |id|
          heavy?(id.split("[", 2).first.delete_prefix("./"))
        end
        distribute(std.sort + heavy.sort)
      end

      # Greedy LPT packing: files are weighted by the sum of their examples'
      # timings (unknown examples get the median), files heavier than the split
      # threshold are packed example by example. Deterministic on identical
      # input, so every parallel node computes the same partition.
      def timed_job_examples
        loads = Array.new(job_count, 0.0)
        own_items = []

        weighted_items.sort_by { |item, weight| [-weight, item] }.each do |item, weight|
          node = loads.each_with_index.min_by { |load, index| [load, index] }.last
          loads[node] += weight
          own_items << item if node == job_index - 1
        end

        own_items.sort
      end

      def weighted_items
        example_ids.group_by { |id| id.split("[", 2).first }.flat_map do |file, ids|
          weights = ids.map { |id| [id, timings.fetch(id, default_example_weight)] }
          total = weights.sum(&:last)
          total > split_threshold ? weights : [[file, total]]
        end
      end

      def timings
        @timings ||=
          begin
            parsed = options[:timings_file] ? JSON.parse(File.read(options[:timings_file])) : {}
            parsed.is_a?(Hash) ? parsed.select { |_id, time| time.is_a?(Numeric) } : {}
          rescue SystemCallError, JSON::ParserError
            {}
          end
      end

      def default_example_weight
        @default_example_weight ||= timings.values.sort[timings.size / 2]
      end

      def split_threshold
        @split_threshold ||= Float(options[:timings_split_threshold] || DEFAULT_SPLIT_THRESHOLD)
      end

      def timings_out
        options[:timings_out]
      end

      def timings_out_arguments
        timings_out ? ["--format", "progress", "--format", "json", "--out", timings_out] : []
      end

      # Rewrites the rspec JSON report into a flat {example_id => seconds} map,
      # the same format consumed via --timings-file.
      def write_flat_timings!
        report = JSON.parse(File.read(timings_out))
        flat = report.fetch("examples").to_h { |ex| [ex.fetch("id"), ex["run_time"].to_f] }
        File.write(timings_out, JSON.dump(flat))
      rescue StandardError => error
        process_stdout.puts("WARNING: failed to save spec timings: #{error.message}")
      end

      def example_ids
        @example_ids ||= Dir.mktmpdir do |dir|
          output_file = File.join(dir, "rspec_examples.json")
          begin
            execute(
              "bundle exec rspec --dry-run --format=json --out #{Shellwords.escape(output_file)}",
              capture: true,
            )
          rescue Error => error
            fail!("RSpec dry-run failed:\n#{error.output}")
          end
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
        boolean_option?(:with_database)
      end

      def with_clickhouse?
        boolean_option?(:with_clickhouse)
      end

      def split_resultset?
        boolean_option?(:split_resultset)
      end
    end
  end
end
