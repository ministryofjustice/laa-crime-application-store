class AddIndexToApplicationVersionOnApplicationIdAndCreatedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "idx_app_ver_final_status_first_decision"
  INDEX_WHERE = "(application ->> 'status') IN ('rejected', 'part_grant', 'granted')"

  def up
    return if index_exists?(:application_version, name: INDEX_NAME)

    add_index :application_version,
              %i[application_id created_at],
              name: INDEX_NAME,
              where: INDEX_WHERE,
              algorithm: :concurrently
  end

  def down
    return unless index_exists?(:application_version, name: INDEX_NAME)

    remove_index :application_version,
                 name: INDEX_NAME,
                 algorithm: :concurrently
  end
end
