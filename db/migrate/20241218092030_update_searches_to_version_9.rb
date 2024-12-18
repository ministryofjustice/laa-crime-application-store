class UpdateSearchesToVersion9 < ActiveRecord::Migration[8.0]
  def change
    update_view :searches, version: 9, revert_to_version: 8
  end
end
