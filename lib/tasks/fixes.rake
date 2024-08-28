namespace :fixes do
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
