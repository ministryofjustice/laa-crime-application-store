# https://dsdmoj.atlassian.net/browse/CRM457-2403

namespace :CRM457_2403 do
  desc "Backfill last_updated_at for Provider Updated submissions"
  task backfill_last_updated_at: :environment do
    # get all provider updated submissions updated after provider app was synchronous, SSOT commit:
    # https://github.com/ministryofjustice/laa-submit-crime-forms/commit/f508f4b09e7b33ff44e1a0b50e293c8458d578c3
    date_from = Date.new(2024, 11, 18)
    submissions = Submission.where("state = ? AND updated_at >= ?", 'expired', date_from)

    submissions.each do |submission|
      # find when last change to provider_updated was
      last_provider_updated = nil
      if submission.application_type == "crm7"
        last_provider_updated = submission.events.select {|event| event['event_type'] == 'new_version' && event['submission_version'] >= 3}
                                                .max {|a,b| a['submission_version'] <=> b['submission_version'] }['created_at']
      elsif submission.application_type == "crm4"
        last_provider_updated = submission.events.select {|event| event['event_type'] == 'provider_updated'}
        .max {|a,b| a['submission_version'] <=> b['submission_version'] }['created_at']
      end

      # update last_updated_at to provider_updated event if it is the most recent relevant event
      if submission.last_updated_at < last_provider_updated
        submission.last_updated_at < last_provider_updated
        submission.save(touch: false)
      end
    end
  end
end
