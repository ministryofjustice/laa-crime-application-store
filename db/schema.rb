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

ActiveRecord::Schema[8.0].define(version: 2024_12_13_150530) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "application", id: :uuid, default: nil, force: :cascade do |t|
    t.integer "current_version", null: false
    t.text "state", null: false
    t.string "application_risk"
    t.text "application_type", null: false
    t.datetime "updated_at", precision: nil
    t.jsonb "caseworker_history_events"
    t.datetime "created_at", precision: nil
    t.datetime "last_updated_at", precision: nil
    t.boolean "notify_subscriber_completed"
    t.string "assigned_user_id"
    t.string "unassigned_user_ids", default: [], array: true
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
    t.boolean "pending", default: false
    t.index ["search_fields"], name: "index_application_version_on_search_fields", using: :gin
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
  create_view "submission_by_services", sql_definition: <<-SQL
      SELECT COALESCE((app_ver.application ->> 'service_type'::text), 'not_found'::text) AS service_type,
      date_trunc('DAY'::text, app.created_at) AS date_submitted,
      count(*) AS submissions
     FROM (application app
       JOIN application_version app_ver ON (((app.id = app_ver.application_id) AND (app_ver.version = 1))))
    WHERE (app.application_type = 'crm4'::text)
    GROUP BY COALESCE((app_ver.application ->> 'service_type'::text), 'not_found'::text), (date_trunc('DAY'::text, app.created_at));
  SQL
  create_view "autogrant_events", sql_definition: <<-SQL
      SELECT a.id,
      av.version AS submission_version,
      (av.created_at)::date AS event_on,
      (av.application ->> 'service_type'::text) AS service_key,
      COALESCE((av.application ->> 'custom_service_name'::text), (COALESCE(t.translation, ((av.application ->> 'service_type'::text))::character varying))::text) AS service
     FROM ((application_version av
       JOIN application a ON (((a.id = av.application_id) AND (a.current_version = av.version))))
       LEFT JOIN translations t ON ((((t.key)::text = (av.application ->> 'service_type'::text)) AND ((t.translation_type)::text = 'service'::text))))
    WHERE (a.state = 'auto_grant'::text);
  SQL
  create_view "submissions_by_date", sql_definition: <<-SQL
      SELECT counted_values.event_on,
      counted_values.application_type,
      counted_values.submission,
      counted_values.resubmission,
      (counted_values.submission + counted_values.resubmission) AS total
     FROM ( SELECT (av.created_at)::date AS event_on,
              a.application_type,
              count(*) FILTER (WHERE ((av.application ->> 'status'::text) = 'submitted'::text)) AS submission,
              count(*) FILTER (WHERE ((av.application ->> 'status'::text) = 'provider_updated'::text)) AS resubmission
             FROM (application_version av
               LEFT JOIN application a ON ((a.id = av.application_id)))
            GROUP BY a.application_type, ((av.created_at)::date)
            ORDER BY a.application_type, ((av.created_at)::date)) counted_values;
  SQL
  create_view "searches", sql_definition: <<-SQL
      WITH defendants AS (
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
      (app_ver.application ->> 'ufn'::text) AS ufn,
      (app_ver.application ->> 'laa_reference'::text) AS laa_reference,
      ((app_ver.application -> 'firm_office'::text) ->> 'name'::text) AS firm_name,
      ((app_ver.application -> 'firm_office'::text) ->> 'account_number'::text) AS account_number,
      (app_ver.application ->> 'service_name'::text) AS service_name,
      app_ver.created_at AS last_state_change,
          CASE app.application_risk
              WHEN 'high'::text THEN 3
              WHEN 'medium'::text THEN 2
              ELSE 1
          END AS risk_level,
      def.client_name,
      app_ver.search_fields,
      app.unassigned_user_ids,
      app.assigned_user_id,
      app.created_at AS date_submitted,
      app.last_updated_at AS last_updated,
          CASE
              WHEN ((app.state = 'submitted'::text) AND (app.assigned_user_id IS NOT NULL)) THEN 'in_progress'::text
              WHEN ((app.state = 'submitted'::text) AND (app.assigned_user_id IS NULL)) THEN 'not_assigned'::text
              ELSE app.state
          END AS status_with_assignment,
      app.application_type,
      app.application_risk AS risk
     FROM ((application app
       JOIN application_version app_ver ON (((app.id = app_ver.application_id) AND (app.current_version = app_ver.version))))
       JOIN defendants def ON ((def.id = app.id)));
  SQL
end
