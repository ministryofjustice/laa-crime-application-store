class AddCompositIndexToApplicationVersions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction! #allows concurrently

  def up
    unless index_exists?(:application_version, %i[application_id version], name: "idx_application_versions_app_id_version")
      add_index :application_version,
                %i[application_id version],
                name: "idx_application_versions_app_id_version",
                algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:application_version, name: "idx_application_versions_app_id_version")
      remove_index :application_version,
                   name: "idx_application_versions_app_id_version",
                   algorithm: :concurrently
    end
  end
end
