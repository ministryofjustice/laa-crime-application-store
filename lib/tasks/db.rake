namespace :db do
  namespace :preparation do
    desc "Run db:prepare and retry if 2-pods-running-this-at-once issues encountered"
    task run_with_retry: :environment do
      attempts = 0
      begin
        Rake::Task["db:prepare"].reenable
        Rake::Task["db:prepare"].invoke
      # If 2 pods try to run a migration at once on the same database, a ConcurrentMigrationError may be encountered.
      # If 2 pods try to do initial setup at once on the same database, a RecordNotUnique error may be encountered
      # as they both try to create the schema_migrations table. RecordNotUnique could indicate an error with the
      # migration itself. If so, this will keep failing after multiple retries so will eventually be raised here.
      rescue ActiveRecord::ConcurrentMigrationError, ActiveRecord::RecordNotUnique
        attempts += 1
        if attempts <= 3
          sleep(5)
          retry
        else
          raise
        end
      end
    end
  end
end
