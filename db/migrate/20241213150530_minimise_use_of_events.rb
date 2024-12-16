class MinimiseUseOfEvents < ActiveRecord::Migration[8.0]
  def change
    # Switch to a version of this view that doesn't look at the events column
    update_view :autogrant_events, version: 3, revert_to_version: 2

    # And likewise this view
    update_view :submissions_by_date, version: 4, revert_to_version: 3

    # Drop some views that dig deep into the events column but aren't actually needed
    drop_view :eod_assignment_count, revert_to_version: 1
    drop_view :all_events, revert_to_version: 2
    drop_view :events_raw, revert_to_version: 1

    # Change the search view to stop looking at the `has_been_assigned_to` virtual column
    # which reads the event column
    update_view :searches, version: 8, revert_to_version: 7

    # And then remove the has_been_assigned_to virtual column entirely
    remove_column(
      :application,
      :has_been_assigned_to,
      :virtual,
      as: "jsonb_path_query_array(events, '$[*] ? (@.event_type == \"assignment\").primary_user_id')",
      type: :jsonb,
      stored: true
    )

    # Rename the events column to something that signifies that it is purely about the history
    # screen in the caseworker app
    rename_column :application, :events, :caseworker_history_events
  end
end
