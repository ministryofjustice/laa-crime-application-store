
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
end
