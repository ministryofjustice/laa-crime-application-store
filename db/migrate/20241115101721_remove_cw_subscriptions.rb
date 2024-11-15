class RemoveCwSubscriptions < ActiveRecord::Migration[7.2]
  def change
    Subscriber.where(subscriber_type: :caseworker).destroy_all
  end
end
