class CreateAllEvents < ActiveRecord::Migration[7.1]
  def change
    create_view :all_events
  end
end
