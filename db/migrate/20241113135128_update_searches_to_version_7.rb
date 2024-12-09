class UpdateSearchesToVersion7 < ActiveRecord::Migration[7.2]
  def change
    update_view :searches, version: 7, revert_to_version: 6
  end
end
