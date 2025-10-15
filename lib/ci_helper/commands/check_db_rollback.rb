# frozen_string_literal: true

module CIHelper
  module Commands
    class CheckDBRollback < BaseCommand
      def call
        create_and_migrate_database!
        execute_with_env("bundle exec rake db:rollback_new_migrations")
        execute_with_env("bundle exec rake db:migrate")

        if with_clickhouse?
          create_and_migrate_clickhouse_database!
          execute_with_env("bundle exec rake ch:rollback_new_migrations")
          execute_with_env("bundle exec rake ch:migrate")
        end
        0
      end

      private

      def env
        :test
      end

      def with_clickhouse?
        boolean_option(:with_clickhouse)
      end
    end
  end
end
