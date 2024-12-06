class DeleteSubscriber < ActiveRecord::Migration[8.0]
  def change
    drop_table :subscriber
  end
end
