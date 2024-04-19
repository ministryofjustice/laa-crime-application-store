# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_04_19_150436) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "redacted_application_versions", force: :cascade do |t|
    t.uuid "application_id", null: false
    t.integer "version", null: false
    t.integer "json_schema_version", null: false
    t.jsonb "application", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriber", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "subscriber_type", limit: 50, null: false
    t.text "webhook_url", null: false
    t.integer "failed_attempts", default: 0
    t.index ["webhook_url", "subscriber_type"], name: "unique_subcribers", unique: true
  end

  add_foreign_key "application_version", "application", name: "application_version_application_id_fkey"
end
