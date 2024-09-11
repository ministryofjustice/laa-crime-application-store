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

          # delete corrupt record
          version_to_delete.destroy if version_to_delete

          # decrement subsequent record version numbers
          versions_to_decrement = SubmissionVersion.where("application_id = ? AND version > ?", version[:submission_id], version[:version_no])
          versions_to_decrement.each do |record|
            record.version -= 1
            record.save!(touch: false)
          end

          # set correct current_version on Submission
          submission = Submission.find(version[:submission_id])
          submission.current_version = submission.ordered_submission_versions.first.current_version
          submission.save!(touch: false)
        end
     end
  end
end
