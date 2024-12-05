class UpdateSearchesToVersion7 < ActiveRecord::Migration[8.0]
  def change
    update_view :searches, version: 7, revert_to_version: 6
  end
end
