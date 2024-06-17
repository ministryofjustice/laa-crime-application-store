class CreateVersionEvents < ActiveRecord::Migration[7.1]
  def change
    create_view :version_events
  end
end
