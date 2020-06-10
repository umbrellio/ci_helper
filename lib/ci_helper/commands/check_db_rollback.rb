# frozen_string_literal: true

module CIHelper
  module Commands
    class CheckDBRollback < BaseCommand
      def call
        create_and_migrate_database!
        execute_with_env("bundle exec rake db:rollback_new_migrations")
        execute_with_env("bundle exec rake db:migrate")
      end

      private

      def env
        :test
      end
    end
  end
end
