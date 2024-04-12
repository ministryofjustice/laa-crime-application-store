class AddPrimaryKeyToSubscriber < ActiveRecord::Migration[7.0]
  def up
    # ActiveRecord can't handle composite primary keys. It assumes an `id` column
    execute "ALTER TABLE subscriber DROP CONSTRAINT subscriber_pkey;"
    add_column :subscriber, :id, :uuid, primary_key: true, default: "gen_random_uuid()"
  end
end
