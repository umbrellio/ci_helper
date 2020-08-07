# frozen_string_literal: true

module CIHelper
  module Commands
    class CheckSpecSuffixes < BaseCommand
      def call
        target_paths.reject { |path| path.end_with?("_spec.rb") }.tap do |paths|
          fail!("Detected specs without _spec suffix: #{paths.join(" ")}") if paths.any?
        end
        0
      end

      private

      def target_paths
        spec_paths + extra_paths - ignored_paths
      end

      def spec_paths
        base_paths.select do |path|
          next if path.start_with?("spec/support")
          next if path.start_with?("spec/factories")
          next if path.end_with?("context.rb")
          true
        end
      end

      def base_paths
        Dir["spec/*/**/*.rb"]
      end

      def extra_paths
        @extra_paths ||= plural_option(:extra_paths).flat_map { |path| Dir[path] }
      end

      def ignored_paths
        @ignored_paths ||= plural_option(:ignored_paths).flat_map { |path| Dir[path] }
      end
    end
  end
end
