
namespace :adjust do
  desc "Change the status of an application"
  task :status, [:submission_id, :status, :role_to_notify] => :environment do |_, args|
    submission = Submission.find(args.submission_id)
    submission.update!(application_state: args.status)

    next if args.role_to_notify.blank?

    Subscriber.where(subscriber_type: args.role_to_notify).find_each do |subscriber|
      NotifySubscriber.new.perform(subscriber.id, submission.id)
    end
  end

  desc "Set the updated at on historical caseworker versions"
  task updated_at: :environment do
    caseworker_statuses = %w[granted rejected auto_grant part_grant sent_back expired]
    versions = SubmissionVersion.includes(:submission)
                                .where(Arel.sql("application ->> 'status' in (?)", caseworker_statuses))

    versions.each do |version|
      event_for_version = version.submission.events.filter { _1['submission_version'] == (version.version - 1) }
      event = event_for_version.sort_by { _1['updated_at'] }.last

      unless event
        puts "Missing Event #{version.application_id}:#{version.id} from #{version.application['updated_at']}"
        next
      end

      puts "updating #{version.application_id}:#{version.id} from #{version.application['updated_at']} to #{event['updated_at']} FROM #{event['event_type']}"
      version.application['updated_at'] = event['updated_at']

      version.save if ENV['PERSIST_ADJUSTMENT']
    end
  end

  desc "Correct set state in JSON blob"
  task update_state: :environment do
    versions = SubmissionVersion.includes(:submission)
                .joins("join application_version av on av.application_id = application_version.application_id and " \
                      "av.application ->> 'status' = application_version.application ->> 'status' and " \
                      "av.version = application_version.version - 1")


    versions.each do |version|
      if version.version != version.submission.current_version
        puts "Not the last version (believe these are duplicates) #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}, version: #{version.version},  current: #{version.submission.current_version}"
        next
      end

      event_for_version = version.submission.events.filter do
        _1['submission_version'] == (version.version - (version.submission.application_state == 'expired' ? 2 : 1))
      end
      event = event_for_version.sort_by { _1['updated_at'] }.last

      unless event
        puts "Missing Event #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}"
        next
      end

      if version.submission.application_state.in?(["auto_grant", "expired", "grant", "part_grant"])
        puts "Updating #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}"
        version.application['status'] = version.submission.application_state
        version.application['updated_at'] = event['updated_at']

        version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
      else
        puts "Unknown status #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}"
      end
    end
  end

  desc "Fix updated at on last sent back before expiry as expiry version does not update"
  task fix_expired: :environment do
    Submission.where(application_state: 'expired').each do |submission|
      version = submission.ordered_submission_versions[1]
      wrong_event = submission.events.filter { _1['submission_version'] == (version.version - 1) }
                              .sort_by { _1['updated_at'] }.last
      right_event = submission.events.filter { _1['submission_version'] == (version.version - 1) && _1['event_type'] != 'expiry' }
                              .sort_by { _1['updated_at'] }.last

      if wrong_event['updated_at'] != right_event['updated_at'] && version.application['updated_at'] == wrong_event['updated_at']
        puts "Fixing incorrect time #{submission.id}:#{version.id} from #{wrong_event['updated_at']} to #{right_event['updated_at']}"
        version.application['updated_at'] = right_event['updated_at']
        version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
      else
        puts "Time fix not found for #{submission.id}:#{version.id}"
      end
    end
  end

  desc "Fix applications that did not get status update before being sent across"
  task fix_status: :environment do
    versions = SubmissionVersion.where(Arel.sql('application ->> \'status\' = \'draft\'')).where(version: 1)
    versions.each do |version|
      version.application['status'] = 'submitted'
      puts "Updating ID: #{version.application_id}, Version: #{version.version} from #{version.application['status']} to submitted"
      version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
    end
  end

  desc "Fix timestamp on Provider updated where was previous set incorrectly"
  task fix_provider_updated: :environment do
    processing_time = Class.new(ApplicationRecord) do
      self.table_name = :processing_times
    end
    records = processing_time.where(Arel.sql('from_time > to_time')).where(to_status: 'provider_updated')

    records.each do |record|
      version = SubmissionVersion.find_by(application_id: record.id, version: record.version)
      event = version.submission.events.detect { _1['submission_version'] == record.version && _1['event_type'] == 'provider_updated' }

      if event['created_at'] == version.application['updated_at']
        puts "Skipping as no match ID: #{record.id}, Version: #{record.version}"
      else
        puts "Updating ID: #{record.id}, Version: #{record.version} from #{version.application['updated_at']} to #{event['created_at']}"
        version.application['updated_at'] = event['created_at']
        version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
      end
    end
  end
end

