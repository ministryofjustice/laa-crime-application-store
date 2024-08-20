namespace :db do
  namespace :connection do
    desc "Check ActiveRecord connection to database"
    task check_connection: :environment do
      ActiveRecord::Base.establish_connection # Establishes connection
      ActiveRecord::Base.connection # Calls connection object
      # output appropriate response depending on whether ActiveRecord can establish connection or not
      if ActiveRecord::Base.connected?
        print "ActiveRecord was able to establish connection with DB"
      else
        print "ActiveRecord unable to establish connection with DB"
      end
    rescue PG::ConnectionBad, ActiveRecord::ConnectionNotEstablished
      print "ActiveRecord unable to establish connection with DB"
    end
  end

  namespace :preparation do
    desc "Run db:prepare and retry if 2-pods-running-this-at-once issues encountered"
    task run_with_retry: :environment do
      attempts = 0
      begin
        Rake::Task["db:prepare"].reenable
        Rake::Task["db:prepare"].invoke

      # If the DB isn't ready yet, ConnectionNotEstablished will be thrown
      # If 2 pods try to run a migration at once on the same database, a ConcurrentMigrationError may be encountered.
      # If 2 pods try to do initial setup at once on the same database, a RecordNotUnique error may be encountered
      # as they both try to create the schema_migrations table. RecordNotUnique could indicate an error with the
      # migration itself. If so, this will keep failing after multiple retries so will eventually be raised here.
      rescue ActiveRecord::ConcurrentMigrationError,
             ActiveRecord::RecordNotUnique,
             ActiveRecord::ConnectionNotEstablished
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
