# frozen_string_literal: true

module CIHelper
  module Commands
    class CheckDBDevelopment < BaseCommand
      def call
        create_and_migrate_database!
        execute("bundle exec rake db:seed")
      end

      private

      def env
        :development
      end
    end
  end
end
