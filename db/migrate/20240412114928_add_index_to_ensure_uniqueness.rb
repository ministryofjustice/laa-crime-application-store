class AddIndexToEnsureUniqueness < ActiveRecord::Migration[7.0]
  def up
    add_index :subscriber, %i[webhook_url subscriber_type], unique: true, name: "unique_subcribers"
  end

  def down
    remove_index :subscriber, name: "unique_subcribers"
  end
end
