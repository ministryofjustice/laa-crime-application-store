class CreateRedactedApplicationVersion < ActiveRecord::Migration[7.1]
  def change
    create_table :redacted_application_versions do |t|
      t.uuid "application_id", null: false
      t.integer "version", null: false
      t.integer "json_schema_version", null: false
      t.jsonb "application", null: false
      t.timestamps
    end
  end
end
