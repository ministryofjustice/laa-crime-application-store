class BackfillLastUpdatedAt < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Submission.unscoped.each do |submission|
      # Update all last_updated_at columns to be the latest event date
      # or, if no events exist, then the latest application version created_at date.
      #
      latest_event = submission.events&.max_by { |event| event['created_at']&.to_time }

      last_updated_at  = if latest_event
        last_updated_at = latest_event['created_at'].to_time
      else
        submission.latest_version.created_at
      end

      submission.update_columns(last_updated_at:)

      sleep(0.01) # throttle
    end
  end
end
