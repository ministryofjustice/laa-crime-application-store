class CreateAutograntEvents < ActiveRecord::Migration[7.1]
  def change
    create_view :autogrant_events
  end
end
