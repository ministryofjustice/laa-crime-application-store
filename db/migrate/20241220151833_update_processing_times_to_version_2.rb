class UpdateProcessingTimesToVersion2 < ActiveRecord::Migration[8.0]
  def change
    update_view :processing_times, version: 2, revert_to_version: 1
  end
end
