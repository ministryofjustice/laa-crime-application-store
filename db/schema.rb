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

ActiveRecord::Schema[7.1].define(version: 2024_07_08_130210) do
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
    t.virtual "has_been_assigned_to", type: :jsonb, as: "jsonb_path_query_array(events, '$[*]?(@.\"event_type\" == \"assignment\").\"primary_user_id\"'::jsonpath)", stored: true
    t.check_constraint "created_at IS NOT NULL", name: "application_created_at_null"
    t.check_constraint "updated_at IS NOT NULL", name: "application_updated_at_null"
  end

  create_table "application_version", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.integer "version", null: false
    t.integer "json_schema_version", null: false
    t.jsonb "application", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.virtual "search_fields", type: :tsvector, as: "((((to_tsvector('simple'::regconfig, COALESCE(((application -> 'defendant'::text) ->> 'first_name'::text), ''::text)) || to_tsvector('simple'::regconfig, COALESCE(((application -> 'defendant'::text) ->> 'last_name'::text), ''::text))) || to_tsvector('simple'::regconfig, jsonb_path_query_array(application, '$.\"defendants\"[*].\"first_name\"'::jsonpath))) || to_tsvector('simple'::regconfig, jsonb_path_query_array(application, '$.\"defendants\"[*].\"last_name\"'::jsonpath))) || to_tsvector('simple'::regconfig, COALESCE(((application -> 'firm_office'::text) ->> 'name'::text), ''::text)))", stored: true
    t.virtual "ufn", type: :string, as: "COALESCE((application ->> 'ufn'::text), ''::text)", stored: true
    t.virtual "laa_reference", type: :string, as: "COALESCE((application ->> 'laa_reference'::text), ''::text)", stored: true
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
  create_view "submissions_by_date", sql_definition: <<-SQL
      SELECT all_events.event_on,
      all_events.application_type,
      count(*) FILTER (WHERE (all_events.event_type = 'new_version'::text)) AS submission,
      count(*) FILTER (WHERE (all_events.event_type = 'provider_updated'::text)) AS resubmission,
      count(*) AS total
     FROM all_events
    WHERE (all_events.event_type = ANY (ARRAY['new_version'::text, 'provider_updated'::text]))
    GROUP BY all_events.application_type, all_events.event_on
    ORDER BY all_events.application_type, all_events.event_on;
  SQL
  create_view "eod_assignment_count", sql_definition: <<-SQL
      WITH dates AS (
           SELECT (t.day)::date AS day
             FROM generate_series(('2024-06-01 00:00:00'::timestamp without time zone)::timestamp with time zone, CURRENT_TIMESTAMP, 'P1D'::interval) t(day)
          ), application_with_cw AS (
           SELECT all_events.id,
              all_events.event_id,
              all_events.event_type,
              all_events.event_at AS from_at,
              all_events.event_on AS from_on,
              lag((all_events.event_at)::timestamp with time zone, 1, CURRENT_TIMESTAMP) OVER (PARTITION BY all_events.id ORDER BY all_events.event_at DESC) AS to_at,
              lag((all_events.event_on)::timestamp without time zone, 1, (CURRENT_DATE + 'P1D'::interval)) OVER (PARTITION BY all_events.id ORDER BY all_events.event_at DESC) AS to_on
             FROM all_events
            WHERE ((all_events.application_type = 'crm4'::text) AND (all_events.event_type = ANY (ARRAY['new_version'::text, 'provider_updated'::text, 'sent_back'::text, 'decision'::text])))
          ), assignments AS (
           SELECT all_events.id,
              all_events.event_id,
              all_events.event_type,
              all_events.event_at AS assigned_at,
              lag(all_events.event_at) OVER (PARTITION BY all_events.id ORDER BY all_events.event_at DESC) AS unassigned_at
             FROM all_events
            WHERE ((all_events.application_type = 'crm4'::text) AND (all_events.event_type = ANY (ARRAY['assignment'::text, 'unassignment'::text])))
          )
   SELECT dates.day,
      count(DISTINCT application_with_cw.event_id) AS assignable,
      count(DISTINCT assignments.event_id) AS assigned
     FROM ((dates
       LEFT JOIN application_with_cw ON (((dates.day >= application_with_cw.from_on) AND (dates.day < application_with_cw.to_on) AND (application_with_cw.event_type = ANY (ARRAY['new_version'::text, 'provider_updated'::text])))))
       LEFT JOIN assignments ON (((assignments.assigned_at >= application_with_cw.from_at) AND ((assignments.assigned_at)::date <= dates.day) AND ((assignments.assigned_at)::date <= application_with_cw.to_at) AND ((assignments.unassigned_at IS NULL) OR (((assignments.unassigned_at)::date > dates.day) AND ((assignments.unassigned_at)::date <= application_with_cw.to_at))) AND (assignments.event_type = 'assignment'::text))))
    GROUP BY dates.day;
  SQL
  create_view "searches", sql_definition: <<-SQL
      SELECT app.id,
      app_ver.id AS application_version_id,
      app_ver.search_fields,
      app_ver.ufn,
      app_ver.laa_reference,
      app.has_been_assigned_to,
      app.created_at AS date_submitted,
      app.updated_at AS date_updated,
      app.application_state AS status,
      app.application_type AS submission_type,
      app.application_risk AS risk
     FROM (application app
       JOIN application_version app_ver ON (((app.id = app_ver.application_id) AND (app.current_version = app_ver.version))));
  SQL
  create_view "autogrant_events", sql_definition: <<-SQL
      SELECT e.id,
      e.submission_version,
      e.event_on,
      (a.application ->> 'service_type'::text) AS service_type
     FROM (all_events e
       JOIN application_version a ON (((a.application_id = e.id) AND (a.version = e.submission_version))))
    WHERE ((e.application_type = 'crm4'::text) AND (e.event_type = 'auto_decision'::text));
  SQL
end
