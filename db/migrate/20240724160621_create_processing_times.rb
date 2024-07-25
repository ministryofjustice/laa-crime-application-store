class CreateProcessingTimes < ActiveRecord::Migration[7.1]
  def change
    create_view :processing_times
  end
end
