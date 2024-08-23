
namespace :check_autogrants do
  desc "Check submissions with autogranted versions but no auto decision event"
  task :retrieve_all => :environment do
    submissions_missing_event = []
    autogranted_submissions = Submission.where(state: 'auto_grant').order(updated_at: :asc)
    autogranted_submissions.each do |submission|
      autogrant_event = submission.events.filter { _1['event_type'] == 'auto_decision' }
      submissions_missing_event << submission.id unless autogrant_event.present?
    end
    print submissions_missing_event.join(",")
  end
end
