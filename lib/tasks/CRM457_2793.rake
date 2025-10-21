
# given an laa-reference retrieve submitted versions, extract original travel_cost_per_hour
# and use this to correct travel_cost_per_hour=nil in primary quote of submission

namespace :CRM457_2793 do
  desc "Correct travel cost with original"
  task :fix_travel_cost, [:laa_reference] => :environment do |_task, args|
    laa_reference = args[:laa_reference]

    abort("laa_reference missing, e.g. rake CRM457_2793:fix_travel_cost['ABC123']") if laa_reference.blank?

    versions = SubmissionVersion.where("application->>'laa_reference' = ?", laa_reference)

    abort("No SubmissionVersions found for #{laa_reference}") if versions.blank?

    travel_cost_per_hour = versions.find_by(version: 1).application["quotes"]
      .detect { _1['primary'] == true }["travel_cost_per_hour"]

    # version 2 is target version to update
    app = versions.find_by(version: 2)
    app_dup = app.application.deep_dup

    app_dup['quotes'].detect { _1['primary'] == true }
      .merge!("travel_cost_per_hour" => travel_cost_per_hour)

    app.application = app_dup

    if app.save(touch: false)
      puts("app #{app.id} updated: #{app.application}")
    else
      abort("Failed to udpate travel_cost_per_hour for #{laa_reference}")
    end
  end
end
