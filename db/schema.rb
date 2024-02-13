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

ActiveRecord::Schema[7.0].define(version: 2024_02_12_093635) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "submission_versions", id: :bigint, force: :cascade do |t|
    t.bigint "submission_id"
    t.jsonb "data"
    t.integer "json_schema_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_versions_on_submission_id"
  end

  create_table "submissions", id: :bigint, force: :cascade do |t|
    t.string "application_id"
    t.string "application_state"
    t.string "application_risk"
    t.string "application_type"
    t.jsonb "events", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assigned_user_id"
    t.jsonb "unassigned_user_ids", default: []
  end

  add_foreign_key "submission_versions", "submissions"
end
