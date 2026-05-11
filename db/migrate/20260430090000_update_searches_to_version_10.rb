class UpdateSearchesToVersion10 < ActiveRecord::Migration[8.1]
  def change
    update_view :searches, version: 10, revert_to_version: 9
  end
end
