# frozen_string_literal: true

require "logger"
require "sequel/timestamp_migrator_undo_extension"

class SequelManagement
  include Rake::DSL

  MIGRATIONS_PATH = "db/migrate"

  def initialize
    self.logger = Logger.new($stdout)

    define_db_task!
  end

  private

  attr_accessor :logger

  def migrations_path
    self.class::MIGRATIONS_PATH
  end

  def define_db_task!
    namespace :db do
      desc "Rollback all migrations, which doesn't exist in master branch"
      task rollback_new_migrations: :environment do
        abort "Shouldn't run in production mode!" if Rails.env.production?

        logger.info "Begin rolling back new migrations"

        migration_files = `#{git_command}`
        abort "Can't get list of migration files" unless $?&.success?

        original_migrations = migration_files.split.map { |path| File.basename(path) }
        migrations_to_rollback = (migrator.applied_migrations - original_migrations).sort.reverse

        next if migrations_to_rollback.empty?

        logger.info "Rolling back migrations:"
        logger.info migrations_to_rollback.join("\n")

        rollback!(migrations_to_rollback)
      end
    end
  end

  def git_command
    "git ls-tree --name-only origin/master #{migrations_path}/"
  end

  def migrator
    @migrator ||= begin
      full_path = Rails.root.join(migrations_path)
      Sequel::TimestampMigrator.new(DB, full_path, allow_missing_migration_files: true)
    end
  end

  def rollback!(migrations)
    migrations.each do |migration|
      migrator.undo(migration.to_i)
    rescue Sequel::Migrator::Error => error
      if error.message.include?("does not exist in the filesystem")
        logger.info error.message
      else
        raise error
      end
    end
  end
end

SequelManagement.new
