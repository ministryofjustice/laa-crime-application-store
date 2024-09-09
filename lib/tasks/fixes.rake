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
end
