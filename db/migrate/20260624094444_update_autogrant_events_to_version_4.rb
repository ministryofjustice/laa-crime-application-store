class UpdateAutograntEventsToVersion4 < ActiveRecord::Migration[8.1]
  def change
    update_view :autogrant_events, version: 4, revert_to_version: 3
  end
end
