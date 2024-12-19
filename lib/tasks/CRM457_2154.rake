# https://dsdmoj.atlassian.net/browse/CRM457-2154

namespace :CRM457_2154 do
  desc "Append high_value flag to submissions"
  task adds_high_value: :environment do
    # Query to select all submissions that don't have a high_value flag
    # and go through each submission version to add the high_value flag:
    # use cost_summary's gross_cost if present, otherwise use submission's application risk
    versions = SubmissionVersion.includes(:submission)
                            .joins(:submission)
                            .where("application_version.application -> 'cost_summary' ->> 'high_value' IS NULL AND application.application_type = 'crm7'")
    failed_updates = 0
    failed_ids = []

    versions.each do |version|
      high_value = high_value_version?(version)
      version.application = version.application.merge({ 'cost_summary': { 'high_value': high_value }})
      if version.save(touch: false)
        puts "Updated version #{version.version} of submission: #{version.submission.id} (high_value: #{high_value})"
      else
        failed_updates += 1
        failed_ids << version.id
      end
    end

    if failed_updates > 0
      puts "Failed submission version updates: #{failed_updates}"
      puts "Versions failed to update:"
      puts failed_ids
    end
  end

  # High value assessment:
  # If cost_summary is present in version payload use gross_cost...
  # otherwise, use application risk
  def high_value_version?(version)
    if version.application['cost_summary'].present?
      version.application.dig('cost_summary', 'profit_costs', 'gross_cost').to_f >= 5000
    else
      version.submission.application_risk == 'high'
    end
  end
end
