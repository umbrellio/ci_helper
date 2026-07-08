# frozen_string_literal: true

module CIHelper
  module Commands
    class CheckSpecSuffixes < BaseCommand
      def call
        paths = target_paths.grep_v(/_spec\.rb\z/)
        fail!("Detected specs without _spec suffix: #{paths.join(" ")}") if paths.any?
        0
      end

      private

      def target_paths
        spec_paths + extra_paths - ignored_paths
      end

      def spec_paths
        base_paths
          .grep_v(%r{\A(?:spec/support|spec/factories)})
          .grep_v(/context\.rb\z/)
      end

      def base_paths
        path.glob("spec/*/**/*.rb").map { |file| file.relative_path_from(path).to_s }
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
