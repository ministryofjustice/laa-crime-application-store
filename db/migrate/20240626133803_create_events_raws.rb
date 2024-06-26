class CreateEventsRaws < ActiveRecord::Migration[7.1]
  def change
    create_view :events_raw
  end
end
