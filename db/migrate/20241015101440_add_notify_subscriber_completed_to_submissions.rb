class AddNotifySubscriberCompletedToSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :application, :notify_subscriber_completed, :boolean
  end
end
