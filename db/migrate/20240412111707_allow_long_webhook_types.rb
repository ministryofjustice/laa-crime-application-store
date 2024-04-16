class AllowLongWebhookTypes < ActiveRecord::Migration[7.0]
  def up
    change_column :subscriber, :webhook_url, :text
  end

  def down
    change_column :subscriber, :webhook_url, :string, limit: 50
  end
end
