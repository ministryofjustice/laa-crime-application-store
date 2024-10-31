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

ActiveRecord::Schema[7.2].define(version: 2024_10_31_110650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "application", id: :uuid, default: nil, force: :cascade do |t|
    t.integer "current_version", null: false
    t.text "state", null: false
    t.text "application_risk", null: false
    t.text "application_type", null: false
    t.datetime "updated_at", precision: nil
    t.jsonb "events"
    t.datetime "created_at", precision: nil
    t.virtual "has_been_assigned_to", type: :jsonb, as: "jsonb_path_query_array(events, '$[*]?(@.\"event_type\" == \"assignment\").\"primary_user_id\"'::jsonpath)", stored: true
    t.datetime "last_updated_at", precision: nil
    t.boolean "notify_subscriber_completed"
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
    t.virtual "search_fields", type: :tsvector, as: "((((((setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'defendant'::text) ->> 'first_name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\") || setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'defendant'::text) ->> 'last_name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (replace((jsonb_path_query_array(application, '$.\"defendants\"[*].\"first_name\"'::jsonpath))::text, '/'::text, '-'::text))::jsonb), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (replace((jsonb_path_query_array(application, '$.\"defendants\"[*].\"last_name\"'::jsonpath))::text, '/'::text, '-'::text))::jsonb), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'firm_office'::text) ->> 'name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, COALESCE((application ->> 'ufn'::text), ''::text)), 'A'::\"char\")) || setweight(to_tsvector('simple'::regconfig, replace(lower(COALESCE((application ->> 'laa_reference'::text), ''::text)), '-'::text, ''::text)), 'A'::\"char\"))", stored: true
    t.index ["search_fields"], name: "index_application_version_on_search_fields", using: :gin
  end

  create_table "subscriber", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "subscriber_type", limit: 50, null: false
    t.text "webhook_url", null: false
    t.integer "failed_attempts", default: 0
    t.index ["webhook_url", "subscriber_type"], name: "unique_subcribers", unique: true
  end

  create_table "translations", force: :cascade do |t|
    t.string "key"
    t.string "translation"
    t.string "translation_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "translation_type"], name: "index_translations_on_key_and_translation_type", unique: true
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
  create_view "autogrant_events", sql_definition: <<-SQL
      SELECT e.id,
      e.submission_version,
      e.event_on,
      (a.application ->> 'service_type'::text) AS service_key,
      COALESCE((a.application ->> 'custom_service_name'::text), (COALESCE(t.translation, ((a.application ->> 'service_type'::text))::character varying))::text) AS service
     FROM ((all_events e
       JOIN application_version a ON (((a.application_id = e.id) AND (a.version = e.submission_version))))
       LEFT JOIN translations t ON ((((t.key)::text = (a.application ->> 'service_type'::text)) AND ((t.translation_type)::text = 'service'::text))))
    WHERE ((e.application_type = 'crm4'::text) AND (e.event_type = 'auto_decision'::text));
  SQL
  create_view "active_providers", sql_definition: <<-SQL
      WITH submissions AS (
           SELECT application.application_type,
              (application_version.application -> 'office_code'::text) AS office_code,
              date_trunc('week'::text, application_version.created_at) AS submitted_start
             FROM (application_version
               JOIN application ON ((application_version.application_id = application.id)))
            WHERE (application_version.version = 1)
            GROUP BY application.application_type, (application_version.application -> 'office_code'::text), (date_trunc('week'::text, application_version.created_at))
          )
   SELECT submissions.application_type,
      submissions.submitted_start,
      count(DISTINCT submissions.office_code) AS office_codes_submitting_during_the_period,
      ( SELECT count(DISTINCT subs.office_code) AS count
             FROM submissions subs
            WHERE ((submissions.submitted_start >= subs.submitted_start) AND (submissions.application_type = subs.application_type))) AS total_office_codes_submitters,
      jsonb_agg(DISTINCT submissions.office_code) AS office_codes_during_the_period
     FROM submissions
    GROUP BY submissions.application_type, submissions.submitted_start
    ORDER BY submissions.application_type, submissions.submitted_start;
  SQL
  create_view "processing_times", sql_definition: <<-SQL
      WITH base AS (
           SELECT application.id,
              application.application_type,
              application_version.version,
              COALESCE(lag((application_version.application ->> 'status'::text), 1) OVER (PARTITION BY application_version.application_id ORDER BY application_version.version), 'draft'::text) AS from_status,
              (COALESCE(lag((application_version.application ->> 'updated_at'::text), 1) OVER (PARTITION BY application_version.application_id ORDER BY application_version.version), (application_version.application ->> 'created_at'::text)))::timestamp without time zone AS from_time,
              (application_version.application ->> 'status'::text) AS to_status,
              ((application_version.application ->> 'updated_at'::text))::timestamp without time zone AS to_time
             FROM (application_version
               JOIN application ON ((application_version.application_id = application.id)))
          )
   SELECT base.id,
      base.application_type,
      base.version,
      base.from_status,
      base.from_time,
      base.to_status,
      base.to_time,
      (base.from_time)::date AS from_date,
      (base.to_time)::date AS to_date,
      GREATEST(EXTRACT(epoch FROM (base.to_time - base.from_time)), (0)::numeric) AS processing_seconds
     FROM base;
  SQL
  create_view "searches", sql_definition: <<-SQL
      WITH event_types AS (
           SELECT application.id,
              jsonb_path_query_array(application.events, '$[*]?(@."event_type" == "assignment" || @."event_type" == "unassignment")."event_type"'::jsonpath) AS assigment_arr
             FROM application
          ), assignments AS (
           SELECT app_1.id,
                  CASE
                      WHEN ((et.assigment_arr ->> '-1'::integer) = 'assignment'::text) THEN true
                      ELSE false
                  END AS assigned
             FROM (application app_1
               JOIN event_types et ON ((et.id = app_1.id)))
          ), defendants AS (
           SELECT app_1.id,
                  CASE
                      WHEN (app_1.application_type = 'crm4'::text) THEN ((((app_ver_1.application -> 'defendant'::text) ->> 'first_name'::text) || ' '::text) || ((app_ver_1.application -> 'defendant'::text) ->> 'last_name'::text))
                      ELSE ( SELECT (((defendants.value ->> 'first_name'::text) || ' '::text) || (defendants.value ->> 'last_name'::text))
                         FROM jsonb_array_elements((app_ver_1.application -> 'defendants'::text)) defendants(value)
                        WHERE ((defendants.value ->> 'main'::text) = 'true'::text))
                  END AS client_name
             FROM (application app_1
               JOIN application_version app_ver_1 ON (((app_1.id = app_ver_1.application_id) AND (app_1.current_version = app_ver_1.version))))
          )
   SELECT app.id,
      app_ver.id AS application_version_id,
      (app_ver.application ->> 'laa_reference'::text) AS laa_reference,
      ((app_ver.application -> 'firm_office'::text) ->> 'name'::text) AS firm_name,
      def.client_name,
      app_ver.search_fields,
      app.has_been_assigned_to,
      app.created_at AS date_submitted,
      app.last_updated_at AS last_updated,
          CASE
              WHEN ((app.state = 'submitted'::text) AND ass.assigned) THEN 'in_progress'::text
              WHEN ((app.state = 'submitted'::text) AND (NOT ass.assigned)) THEN 'not_assigned'::text
              ELSE app.state
          END AS status_with_assignment,
      app.application_type,
      app.application_risk AS risk
     FROM (((application app
       JOIN application_version app_ver ON (((app.id = app_ver.application_id) AND (app.current_version = app_ver.version))))
       JOIN assignments ass ON ((ass.id = app.id)))
       JOIN defendants def ON ((def.id = app.id)));
  SQL
  create_view "submission_by_services", sql_definition: <<-SQL
      SELECT COALESCE(((app_ver.application -> 'service_type'::text))::text, 'not_found'::text) AS service_type,
      date_trunc('DAY'::text, app.created_at) AS date_submitted
     FROM (application app
       JOIN application_version app_ver ON (((app.id = app_ver.application_id) AND (app_ver.version = 1))))
    WHERE (app.application_type = 'crm4'::text)
    GROUP BY COALESCE(((app_ver.application -> 'service_type'::text))::text, 'not_found'::text), (date_trunc('DAY'::text, app.created_at));
  SQL
  create_view "submissions_by_date", sql_definition: <<-SQL
      SELECT counted_values.event_on,
      counted_values.application_type,
      counted_values.submission,
      counted_values.resubmission,
      (counted_values.submission + counted_values.resubmission) AS total
     FROM ( SELECT all_events.event_on,
              all_events.application_type,
              count(*) FILTER (WHERE ((all_events.event_type = 'new_version'::text) AND (all_events.submission_version = 1))) AS submission,
              count(*) FILTER (WHERE (((all_events.event_type = 'new_version'::text) AND (all_events.submission_version > 1) AND (all_events.application_type = 'crm7'::text)) OR ((all_events.event_type = 'provider_updated'::text) AND (all_events.application_type = 'crm4'::text)))) AS resubmission
             FROM all_events
            WHERE (all_events.event_type = ANY (ARRAY['new_version'::text, 'provider_updated'::text]))
            GROUP BY all_events.application_type, all_events.event_on
            ORDER BY all_events.application_type, all_events.event_on) counted_values;
  SQL
end
