namespace :fixes do
  namespace :mismatched_references do
    desc "Find mismatched LAA references"
    task find: :environment do
      mismatched_submissions = get_mismatched_submissions
      mismatched_submissions.each do |entry|
        puts "Submission ID: #{entry['submission'].id} Original Ref: #{entry['original_ref']} All References: #{entry['unique_references'].join(",")}"
      end
    end

    desc "Fix mismatched LAA references by scanning for mismatches"
    task auto_fix: :environment do
      mismatched_submissions = get_mismatched_submissions
      mismatched_submissions.each do |entry|
        fix_entry(entry)
      end
    end

    desc "Fix mismatched LAA references from list of submission ids"
    task manual_fix: :environment do
      # populate affected_submission_ids with array of submission id strings that need fixing
      affected_submission_ids = []
      affected_submission_ids.each do |submission_id|
        submission = Submission.find(submission_id)
        if submission
          entry = submission_details(submission_id)
          fix_entry(entry)
        end
      end
    end

    def get_mismatched_submissions
      faulty_submissions = []
      submissions_to_check = Submission.where("application.current_version > 2")
      submissions_to_check.each do |submission|
        entry = submission_details(submission)
        if entry['unique_references'].count > 1
          faulty_submissions.push entry
        end
      end
      faulty_submissions
    end

    def submission_details(submission)
      versions = submission.ordered_submission_versions
      original_ref = versions.last.application['laa_reference']
      unique_references = versions.pluck(Arel.sql("application -> 'laa_reference'")).uniq()
      { 'submission' => submission, 'original_ref' => original_ref, 'unique_references' => unique_references}
    end

    def fix_entry(entry)
      submission = entry['submission']
      original_ref = entry['original_ref']
      if entry.present? && original_ref.present?
        puts "Fixing #{entry}"
        versions_to_fix = SubmissionVersion.where({application_id: submission.id})
        versions_to_fix.each do |version|
          current_ref = version.application['laa_reference']
          if current_ref != original_ref
            fixed_application = version.application
            fixed_application['laa_reference'] = original_ref
            version.application = fixed_application
            if version.save!(touch: false)
              puts "Fixed Submission #{version.id}"
            end
          end
        end
      end
    end
  end

  desc "Amend a contact email address. Typically because user has added a valid but undeliverable address"
  task :update_contact_email, [:id, :new_contact_email] => :environment do |_, args|
    submission = Submission.find(args[:id])
    subver = submission.latest_version

    STDOUT.print "This will update #{subver.application['laa_reference']}'s contact email, \"#{subver.application['solicitor']['contact_email'] || 'nil'}\", to \"#{args[:new_contact_email]}\": Are you sure? (y/n): "
    input = STDIN.gets.strip

    if input.downcase.in?(['yes','y'])
      print 'updating...'
      subver.application['solicitor']['contact_email'] = args[:new_contact_email]
      subver.save!(touch: false)
      puts "#{subver.application['laa_reference']}'s contact email is now #{subver.reload.application['solicitor']['contact_email']}"
    end
  end

  desc "Remove corrupt submission versions"
  task fix_corrupt_versions: :environment do
    versions_to_fix = [
      { submission_id: "84fabfe2-844f-4bbe-8460-1be4a18912e3", version_no: 3},
      { submission_id: "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", version_no: 3},
      { submission_id: "603c3d9a-2493-40d5-9691-5339c71c801a", version_no: 1 },
      { submission_id: "dec31825-1bd1-461e-8857-5ddf9f839992", version_no: 2 },
      { submission_id: "6e319bb2-d450-4451-aed5-eeea57d7c329", version_no: 1 }
    ]

    versions_to_fix.each do |version|
      ActiveRecord::Base.transaction do
        version_to_delete = SubmissionVersion.find_by(application_id: version[:submission_id], version: version[:version_no])
        if version_to_delete.present?
          puts "Fixing Submission with id: #{version[:submission_id]}"
          # delete corrupt record
          version_to_delete.destroy
          puts "Removed SubmissionVersion with id: #{version_to_delete.id}"
          # decrement subsequent record version numbers
          versions_to_decrement = SubmissionVersion.where("application_id = ? AND version > ?", version[:submission_id], version[:version_no])
          versions_to_decrement.each do |record|
            record.version -= 1
            record.save!(touch: false)
          end
          puts "Decremented SubmissionVersions for #{version[:submission_id]} with versions >#{version[:version_no]}"

          # set correct current_version on Submission
          submission = Submission.find_by(id: version[:submission_id])
          if submission.present?
            submission.current_version = submission.ordered_submission_versions.first.version
            submission.save!(touch: false)
            puts "Set current_version for Submission with id: #{version[:submission_id]} to correct value"
          end
        else
          puts "SubmissionVersion not found"
        end
      end
    end
  end

  desc "Fix corrupt submission events"
  task fix_corrupt_events: :environment do
    submission_1_id = "dec31825-1bd1-461e-8857-5ddf9f839992"
    # Update final submission event to have submission_version = 2
    update_event_submission_version(submission_1_id, "d3003451-39f5-48c3-ba9f-f210491dad9b", 2)

    submission_2_id = "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0"
    # 1. Update first sent_back submission event to have submission_version = 2
    # 2. Update second sent_back submission event to have submission_version = 4
    # 3. Update second provider_updated submission event to have submission_version = 5
    # 4. Update subsequent assignment event to have submission_version = 5
    # 5. Update third provider_updated submission event to have submission_version = 7
    # 6. Update all subsequent events apart from decision to have submission_version = 7
    update_event_submission_version(submission_2_id, "8629eeed-c898-4232-bd99-e8c1ef4b2517", 2)
    update_event_submission_version(submission_2_id, "22c6f283-5197-4f22-a3b3-f000b926a476", 4)
    update_event_submission_version(submission_2_id, "1f03be18-ed56-4e16-a90f-b40ecb1b2865", 5)
    update_event_submission_version(submission_2_id, "48b9359e-3cd6-4c48-aba4-bf85dabff5fb", 5)
    update_event_submission_version(submission_2_id, "4c72a40a-df29-4dce-881e-6b082b1bb234", 7)
    update_event_submission_version(submission_2_id, "55b111aa-edd6-4349-bb42-16903359d455", 7)
    update_event_submission_version(submission_2_id, "7b4a1f1f-230d-458f-8e63-dd9d7ad372da", 7)
    update_event_submission_version(submission_2_id, "1b903d5f-4b98-400c-a683-a4330c4eb56d", 7)


  end

  def update_event_submission_version(submission_id, event_id, submission_version)
    submission = Submission.find_by(id: submission_id)
    if submission.present?
      event_to_change = submission.events.find { |event| event["id"] == event_id }
      event_index = submission.events.find_index(event_to_change)
      event_to_change["submission_version"] = submission_version
      submission.events[event_index] = event_to_change
      submission.save!(touch: false)
      puts "Event: #{event_id} for Submission: #{submission_id} submission_version updated to #{submission_version}"
    end
  end
end
