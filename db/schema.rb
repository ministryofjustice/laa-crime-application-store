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

ActiveRecord::Schema[7.1].define(version: 2024_06_26_134140) do
  create_schema "analytics"

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "application", id: :uuid, default: nil, force: :cascade do |t|
    t.integer "current_version", null: false
    t.text "application_state", null: false
    t.text "application_risk", null: false
    t.text "application_type", null: false
    t.datetime "updated_at", precision: nil
    t.jsonb "events"
    t.datetime "created_at", precision: nil
    t.check_constraint "created_at IS NOT NULL", name: "application_created_at_null", validate: false
    t.check_constraint "updated_at IS NOT NULL", name: "application_updated_at_null", validate: false
  end

  create_table "application_version", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.integer "version", null: false
    t.integer "json_schema_version", null: false
    t.jsonb "application", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "subscriber", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "subscriber_type", limit: 50, null: false
    t.text "webhook_url", null: false
    t.integer "failed_attempts", default: 0
    t.index ["webhook_url", "subscriber_type"], name: "unique_subcribers", unique: true
  end

  add_foreign_key "application_version", "application", name: "application_version_application_id_fkey"

  create_view "events_raw", sql_definition: <<-SQL
      SELECT application.id,
      application.application_type,
      jsonb_array_elements(application.events) AS event_json
     FROM application;
  SQL
  create_view "all_events", sql_definition: <<-SQL
      SELECT events_raw.id,
      events_raw.application_type,
      events_raw.event_json,
      (events_raw.event_json ->> 'id'::text) AS event_id,
      ((events_raw.event_json ->> 'submission_version'::text))::integer AS submission_version,
      (events_raw.event_json ->> 'event_type'::text) AS event_type,
      ((events_raw.event_json ->> 'created_at'::text))::timestamp without time zone AS event_at,
      (((events_raw.event_json ->> 'created_at'::text))::timestamp without time zone)::date AS event_on,
      ((events_raw.event_json ->> 'primary_user_id'::text))::integer AS primary_user_id,
      ((events_raw.event_json ->> 'secondary_user_id'::text))::integer AS secondary_user_id,
      (events_raw.event_json -> 'details'::text) AS details
     FROM events_raw;
  SQL
  create_view "submissions_by_dates", sql_definition: <<-SQL
      SELECT all_events.event_on,
      count(*) FILTER (WHERE (all_events.event_type = 'new_version'::text)) AS submission,
      count(*) FILTER (WHERE (all_events.event_type = 'provider_updated'::text)) AS resubmission,
      count(*) AS total
     FROM all_events
    WHERE ((all_events.application_type = 'crm4'::text) AND (all_events.event_type = ANY (ARRAY['new_version'::text, 'provider_updated'::text])))
    GROUP BY all_events.event_on
    ORDER BY all_events.event_on;
  SQL
end
