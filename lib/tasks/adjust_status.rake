
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
end
