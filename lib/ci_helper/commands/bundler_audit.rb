# frozen_string_literal: true

module CIHelper
  module Commands
    class BundlerAudit < BaseCommand
      def call
        execute(audit_cmd)
      end

      private

      def audit_cmd
        (+"bundle exec bundler-audit check --update").tap do |audit_cmd|
          if ignored_advisories.any?
            audit_cmd << " --ignore #{ignored_advisories.join(" ")}"
          end
        end
      end

      def ignored_advisories
        @ignored_advisories ||= plural_option(:ignored_advisories)
      end
    end
  end
end
