class AddIndexToApplicationOnApplicationTypeAndLastUpdatedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "idx_application_on_type_last_updated_at"

  def up
    return if index_exists?(:application, %i[application_type last_updated_at], name: INDEX_NAME)

    add_index :application,
              %i[application_type last_updated_at],
              name: INDEX_NAME,
              algorithm: :concurrently
  end

  def down
    return unless index_exists?(:application, name: INDEX_NAME)

    remove_index :application,
                 name: INDEX_NAME,
                 algorithm: :concurrently
  end
end
