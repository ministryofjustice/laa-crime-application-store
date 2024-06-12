class CreateRedactedApplicationVersion < ActiveRecord::Migration[7.1]
  def change
    create_table :redacted_application_versions, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "submission_id"
      t.uuid "submission_version_id"
      t.integer "version"
      t.integer "json_schema_version"
      t.jsonb "application"
      t.timestamps
    end
  end
end
