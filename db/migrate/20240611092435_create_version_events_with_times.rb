class CreateVersionEventsWithTimes < ActiveRecord::Migration[7.1]
  def change
    create_view :version_events_with_times
  end
end
