class UpdateAutograntEventsToVersion2 < ActiveRecord::Migration[7.1]
  def up
    update_view :autogrant_events, version: 2, revert_to_version: 1
  end
end
