class MissingEventFields < ActiveRecord::Migration[7.1]
  def change
    Submission
      .where("events @> '[{\"event_type\": \"provider_updated\"}]'").
      .each do |submission|
        last_version = nil
        submission.events.each do |event|
          last_version = [last_version, event["submission_version"]].compact.max

          next if event["created_at"]
          next unless event["event_type"] == 'provider_updated'

          event["submission_version"] = last_version + 1
          version = submission.ordered_submission_versions.detect { _1.version == event["submission_version"] }

          event["created_at"] ||= version.created_at
          event["updated_at"] ||= version.created_at
        end

        submission.save
      end
  end
end
