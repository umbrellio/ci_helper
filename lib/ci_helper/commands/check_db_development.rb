# frozen_string_literal: true

module CIHelper
  module Commands
    class CheckDBDevelopment < BaseCommand
      def call
        create_and_migrate_database!
        execute("bundle exec rake db:seed")
        create_and_migrate_clickhouse_database! if with_clickhouse?
        0
      end

      private

      def env
        :development
      end

      def with_clickhouse?
        boolean_option(:with_clickhouse)
      end
    end
  end
end
