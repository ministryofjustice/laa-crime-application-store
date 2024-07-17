class UpdateSearchesToVersion4 < ActiveRecord::Migration[7.1]
  def change
    update_view :searches, version: 4, revert_to_version: 3
  end
end
