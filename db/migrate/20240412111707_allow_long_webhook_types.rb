class AllowLongWebhookTypes < ActiveRecord::Migration[7.0]
  def up
    change_column :subscriber, :webhook_url, :string, limit: 250
  end
end
