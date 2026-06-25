class AddAutograntEventsFilterIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "idx_application_auto_grant_current_version".freeze

  def up
    return if index_exists?(:application, name: INDEX_NAME)

    add_index(
      :application,
      %i[id current_version],
      name: INDEX_NAME,
      where: "state = 'auto_grant'",
      algorithm: :concurrently,
    )
  end

  def down
    return unless index_exists?(:application, name: INDEX_NAME)

    remove_index(
      :application,
      name: INDEX_NAME,
      algorithm: :concurrently,
    )
  end
end
