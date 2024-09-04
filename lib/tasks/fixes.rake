namespace :fixes do
  desc "Find mismatched LAA references"
  task find_mismatched_references: :environment do
    submissions_to_check = Submission.where("application.current_version > 2")
    submissions_to_check.each do |submission|
      versions = submission.ordered_submission_versions
      unique_references = versions.pluck(Arel.sql("application -> 'laa_reference'")).uniq().sort
      if unique_references.count > 1
        print "Submission ID: #{submission.id} Original Ref: #{versions.first.application['laa_reference']} All References: #{unique_references.join(",")}}"
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
