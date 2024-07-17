class BackfillLastUpdatedAt < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Submission.unscoped.each do |submission|
      # Update all last_updated_at columns to be the latest event date
      # or, if no events exist, then the latest application version created_at date.
      #

      # default to created_at of current verions
      last_updated_at = submission.latest_version.created_at

      # Events may not exist or dirty data means some may not have certain expected fields
      if submission.events
        usable_events = submission.events.select {|ev| ev['created_at'].present? }

        if usable_events.any?
          latest_event = usable_events.max_by { |ev| ev["created_at"].to_time }
          last_updated_at = latest_event['created_at'].to_time
        end
      end

      submission.update_columns(last_updated_at:)

      sleep(0.01) # throttle
    rescue StandardError => e
      Rails.logger.info("Backfill of last_updated_at failed with #{e}")
    end
  end
end
