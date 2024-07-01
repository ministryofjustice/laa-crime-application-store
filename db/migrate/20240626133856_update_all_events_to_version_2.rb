class UpdateAllEventsToVersion2 < ActiveRecord::Migration[7.1]
  def up
    drop_view :version_events_with_times
    drop_view :version_events
    update_view :all_events, version: 2, revert_to_version: 1
  end
end
