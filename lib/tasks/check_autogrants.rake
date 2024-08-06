
namespace :check_autogrants do
  desc "Check submissions with autogranted versions but no auto decision event"
  task :retrieve_all => :environment do |_, args|
    submissions_missing_event = []
    autogranted_submissions = Submission.where(application_state: 'auto_grant')
    autogranted_submissions.each do |submission|
      autogrant_event = submission.events.filter { _1['event_type'] == 'auto_decision' }
      submissions_missing_event << submission.id
    end
    puts submissions_missing_event
  end
end
