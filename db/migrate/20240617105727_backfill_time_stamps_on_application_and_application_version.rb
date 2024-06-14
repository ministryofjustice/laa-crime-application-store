class BackfillTimeStampsOnApplicationAndApplicationVersion < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Update Submissions without events to have created_at the same as updated_at
    Submission.unscoped.where(created_at: nil, events: nil).in_batches do |relation|
      relation.update_all("created_at = updated_at")
      sleep 0.1
    end

    # Update Submissions with events to have created_at matching earliest/first events created_at (new_version||auto_decision)
    Submission.unscoped.where(created_at: nil).where.not(events: nil).each do |submission|
      created_at = submission.events.first['created_at'].in_time_zone

      submission.update_columns(created_at:)
      sleep 0.01
    end

    # Update SubmissionsVersions with version: 1 to have created_at and updated_at matching the created_at date for their application as set above
    sql = <<~SQL
      UPDATE application_version as app_v
      SET created_at = app.created_at,
          updated_at = app.created_at
      FROM application as app
      WHERE app.id = app_v.application_id
        AND app_v.version = 1
    SQL

    ActiveRecord::Base.connection.execute(sql)

    # Update SubmissionsVersions with version: 2+ to have created_at/updated_at matching the created_at ????
    # LEFT OUT as there is no reliable way to map events to submission versions.
  end
end
