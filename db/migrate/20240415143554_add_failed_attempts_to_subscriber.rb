class AddFailedAttemptsToSubscriber < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriber, :failed_attempts, :integer, default: 0
  end
end
