class BackfillLastUpdatedAt < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Submission.unscoped.each do |submission|
      # Update all last_updated_at columns to be the latest event date
      # or, if no events exist, then the latest application version created_at date.
      #
      last_updated_at = if submission.events.any?
        latest_event = submission.events&.max_by { |event| event['created_at']&.to_time }
        latest_event['created_at'].to_time
      else
        submission.latest_version.created_at
      end

      submission.update_columns(last_updated_at:)

      sleep(0.01) # throttle
    rescue StandardError => e
      Rails.logger.info("Backfill of last_updated_at failed with #{e}")
    end
  end
end
