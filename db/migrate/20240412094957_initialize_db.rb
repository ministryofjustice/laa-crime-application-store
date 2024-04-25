class InitializeDb < ActiveRecord::Migration[7.0]
  # rubocop:disable Rails/ReversibleMigration
  # rubocop:disable Rails/CreateTableWithTimestamps
  def change
    # If we are taking over an existing database set up by python, these will already exist
    existing = execute("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'application')")
    return if existing[0]["exists"]

    create_table "application", id: :uuid, default: nil, force: :cascade do |t|
      t.integer "current_version", null: false
      t.text "application_state", null: false
      t.text "application_risk", null: false
      t.text "application_type", null: false
      t.datetime "updated_at", precision: nil
      t.jsonb "events"
    end

    create_table "application_version", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "application_id", null: false
      t.integer "version", null: false
      t.integer "json_schema_version", null: false
      t.jsonb "application", null: false
    end

    create_table "subscriber", primary_key: %w[webhook_url subscriber_type], force: :cascade do |t|
      t.string "subscriber_type", limit: 50, null: false
      t.string "webhook_url", limit: 50, null: false
    end

    add_foreign_key "application_version", "application", name: "application_version_application_id_fkey"
  end
  # rubocop:enable Rails/ReversibleMigration
  # rubocop:enable Rails/CreateTableWithTimestamps
end
