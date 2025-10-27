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

ActiveRecord::Schema[8.1].define(version: 2025_10_27_113529) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "postgis"

  create_table "application", id: :uuid, default: nil, force: :cascade do |t|
    t.string "application_risk"
    t.text "application_type", null: false
    t.string "assigned_user_id"
    t.jsonb "caseworker_history_events"
    t.datetime "created_at", precision: nil
    t.integer "current_version", null: false
    t.datetime "last_updated_at", precision: nil
    t.boolean "notify_subscriber_completed"
    t.uuid "nsm_claim_id"
    t.text "state", null: false
    t.string "unassigned_user_ids", default: [], array: true
    t.datetime "updated_at", precision: nil
    t.check_constraint "created_at IS NOT NULL", name: "application_created_at_null"
    t.check_constraint "updated_at IS NOT NULL", name: "application_updated_at_null"
  end

  create_table "application_version", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "application", null: false
    t.uuid "application_id", null: false
    t.datetime "created_at", precision: nil
    t.integer "json_schema_version", null: false
    t.boolean "pending", default: false
    t.virtual "search_fields", type: :tsvector, as: "((((((setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'defendant'::text) ->> 'first_name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\") || setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'defendant'::text) ->> 'last_name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (replace((jsonb_path_query_array(application, '$.\"defendants\"[*].\"first_name\"'::jsonpath))::text, '/'::text, '-'::text))::jsonb), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (replace((jsonb_path_query_array(application, '$.\"defendants\"[*].\"last_name\"'::jsonpath))::text, '/'::text, '-'::text))::jsonb), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'firm_office'::text) ->> 'name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, COALESCE((application ->> 'ufn'::text), ''::text)), 'A'::\"char\")) || setweight(to_tsvector('simple'::regconfig, replace(lower(COALESCE((application ->> 'laa_reference'::text), ''::text)), '-'::text, ''::text)), 'A'::\"char\"))", stored: true
    t.datetime "updated_at", precision: nil
    t.integer "version", null: false
    t.index ["search_fields"], name: "index_application_version_on_search_fields", using: :gin
  end

  create_table "failed_imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "details"
    t.string "error_type"
    t.uuid "provider_id", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_request_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "client_first_name"
    t.string "client_last_name"
    t.string "counsel_firm_name"
    t.string "counsel_office_code"
    t.integer "court_attendances"
    t.string "court_name"
    t.datetime "created_at", null: false
    t.string "laa_reference"
    t.string "matter_type"
    t.integer "no_of_defendants"
    t.uuid "nsm_claim_id"
    t.string "outcome_code"
    t.string "solicitor_firm_name"
    t.string "solicitor_office_code"
    t.string "stage_code"
    t.string "type"
    t.string "ufn"
    t.datetime "updated_at", null: false
    t.datetime "work_completed_date"
    t.boolean "youth_court"
    t.index ["client_last_name"], name: "index_payment_request_claims_on_client_last_name"
    t.index ["laa_reference"], name: "index_payment_request_claims_on_laa_reference"
    t.index ["solicitor_office_code"], name: "index_payment_request_claims_on_solicitor_office_code"
    t.index ["type"], name: "index_payment_request_claims_on_type"
    t.index ["ufn"], name: "index_payment_request_claims_on_ufn"
  end

  create_table "payment_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "allowed_assigned_counsel_vat", precision: 10, scale: 2
    t.decimal "allowed_disbursement_cost", precision: 10, scale: 2
    t.decimal "allowed_net_assigned_counsel_cost", precision: 10, scale: 2
    t.decimal "allowed_profit_cost", precision: 10, scale: 2
    t.decimal "allowed_total", precision: 10, scale: 2
    t.decimal "allowed_travel_cost", precision: 10, scale: 2
    t.decimal "allowed_waiting_cost", precision: 10, scale: 2
    t.decimal "assigned_counsel_vat", precision: 10, scale: 2
    t.decimal "claimed_total", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "date_received"
    t.decimal "disbursement_cost", precision: 10, scale: 2
    t.decimal "net_assigned_counsel_cost", precision: 10, scale: 2
    t.uuid "payment_request_claim_id"
    t.decimal "profit_cost", precision: 10, scale: 2
    t.string "request_type"
    t.datetime "submitted_at"
    t.uuid "submitter_id"
    t.decimal "travel_cost", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.decimal "waiting_cost", precision: 10, scale: 2
    t.index ["payment_request_claim_id"], name: "index_payment_requests_on_payment_request_claim_id"
  end

  create_table "translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.string "translation"
    t.string "translation_type"
    t.datetime "updated_at", null: false
    t.index ["key", "translation_type"], name: "index_translations_on_key_and_translation_type", unique: true
  end

  add_foreign_key "application_version", "application", name: "application_version_application_id_fkey"
  add_foreign_key "payment_request_claims", "payment_request_claims", column: "nsm_claim_id"
  add_foreign_key "payment_requests", "payment_request_claims"

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
  create_view "additional_fee_uptakes", sql_definition: <<-SQL
      WITH dates AS (
           SELECT (t.day)::date AS day
             FROM generate_series(('2024-12-06 00:00:00'::timestamp without time zone)::timestamp with time zone, CURRENT_TIMESTAMP, 'P1D'::interval) t(day)
          ), claims AS (
           SELECT
                  CASE
                      WHEN ((((application_version.application ->> 'include_youth_court_fee'::text))::boolean IS TRUE) AND ((application_version.application ->> 'status'::text) = 'submitted'::text)) THEN 1
                      ELSE 0
                  END AS youth_court_fee_claimed,
                  CASE
                      WHEN ((((application_version.application ->> 'plea_category'::text) = 'category_1a'::text) OR ((application_version.application ->> 'plea_category'::text) = 'category_2a'::text)) AND ((application_version.application ->> 'youth_court'::text) = 'yes'::text) AND ((application_version.application ->> 'status'::text) = 'submitted'::text)) THEN 1
                      ELSE 0
                  END AS youth_court_fee_eligible,
                  CASE
                      WHEN ((((application_version.application ->> 'include_youth_court_fee'::text))::boolean IS TRUE) AND ((application_version.application ->> 'status'::text) = ANY (ARRAY['granted'::text, 'part_grant'::text, 'rejected'::text]))) THEN 1
                      ELSE 0
                  END AS youth_court_fee_approved,
                  CASE
                      WHEN ((((application_version.application ->> 'include_youth_court_fee'::text))::boolean IS FALSE) AND (((application_version.application ->> 'include_youth_court_fee_original'::text))::boolean IS TRUE) AND ((application_version.application ->> 'status'::text) = ANY (ARRAY['granted'::text, 'part_grant'::text, 'rejected'::text]))) THEN 1
                      ELSE 0
                  END AS youth_court_fee_rejected,
              application_version.created_at
             FROM application_version
            WHERE ((application_version.application ->> 'status'::text) = ANY (ARRAY['submitted'::text, 'granted'::text, 'part_grant'::text, 'rejected'::text]))
          )
   SELECT dates.day AS event_date,
      COALESCE(sum(claims.youth_court_fee_claimed), (0)::bigint) AS youth_court_fee_claimed_count,
      COALESCE(sum(claims.youth_court_fee_eligible), (0)::bigint) AS youth_court_fee_eligible_count,
      COALESCE(sum(claims.youth_court_fee_approved), (0)::bigint) AS youth_court_fee_approved_count,
      COALESCE(sum(claims.youth_court_fee_rejected), (0)::bigint) AS youth_court_fee_rejected_count
     FROM (dates
       LEFT JOIN claims ON ((dates.day = date(claims.created_at))))
    GROUP BY dates.day
    ORDER BY dates.day;
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
  create_view "import_counts", sql_definition: <<-SQL
      SELECT (app_ver.created_at)::date AS submitted_date,
          CASE
              WHEN (((app_ver.application ->> 'import_date'::text))::timestamp without time zone IS NOT NULL) THEN true
              ELSE false
          END AS claim_imported
     FROM (application_version app_ver
       LEFT JOIN application app ON (((app.id = app_ver.application_id) AND (app_ver.pending IS FALSE) AND (app_ver.version = 1))))
    ORDER BY ((app_ver.created_at)::date);
  SQL
  create_view "processing_times", sql_definition: <<-SQL
      WITH base AS (
           SELECT application.id,
              application.application_type,
              application_version.version,
              COALESCE(lag((application_version.application ->> 'status'::text), 1) OVER (PARTITION BY application_version.application_id ORDER BY application_version.version), 'draft'::text) AS from_status,
              (COALESCE(lag((application_version.application ->> 'updated_at'::text), 1) OVER (PARTITION BY application_version.application_id ORDER BY application_version.version), (application_version.application ->> 'created_at'::text)))::timestamp without time zone AS from_time,
              (application_version.application ->> 'status'::text) AS to_status,
              ((application_version.application ->> 'updated_at'::text))::timestamp without time zone AS to_time,
                  CASE
                      WHEN (((application_version.application ->> 'import_date'::text))::timestamp without time zone IS NOT NULL) THEN true
                      ELSE false
                  END AS claim_imported
             FROM (application_version
               JOIN application ON (((application_version.application_id = application.id) AND (application_version.pending IS FALSE))))
          )
   SELECT base.id,
      base.application_type,
      base.version,
      base.from_status,
      base.from_time,
      base.to_status,
      base.to_time,
      base.claim_imported,
      (base.from_time)::date AS from_date,
      (base.to_time)::date AS to_date,
      GREATEST(EXTRACT(epoch FROM (base.to_time - base.from_time)), (0)::numeric) AS processing_seconds
     FROM base;
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
      (((app_ver.application -> 'cost_summary'::text) ->> 'high_value'::text))::boolean AS high_value,
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
  create_view "submission_assess_times", sql_definition: <<-SQL
      WITH base AS (
           SELECT application.id,
              application.application_type,
              application.created_at AS submission_date,
              (first_decision.application ->> 'status'::text) AS first_decision,
              (first_decision.application ->> 'office_code'::text) AS office_code,
              first_decision.decision_created_at AS first_decision_date
             FROM (application
               JOIN ( SELECT application_version.application_id,
                      application_version.application,
                      min(application_version.created_at) AS decision_created_at
                     FROM application_version
                    GROUP BY application_version.application_id, application_version.application) first_decision ON ((application.id = first_decision.application_id)))
            WHERE (((first_decision.application ->> 'status'::text) = ANY (ARRAY['rejected'::text, 'part_grant'::text, 'granted'::text])) AND (first_decision.decision_created_at IS NOT NULL))
          ), assignment_events AS (
           SELECT application.id,
              ((events.value ->> 'created_at'::text))::timestamp without time zone AS assigned_at
             FROM (application
               CROSS JOIN LATERAL jsonb_array_elements(application.caseworker_history_events) events(value))
            WHERE ((events.value ->> 'event_type'::text) = 'assignment'::text)
          )
   SELECT base.id,
      base.application_type,
      base.submission_date,
      base.office_code,
      base.first_decision,
      base.first_decision_date,
      first_assignment.first_assigned_date,
      (EXTRACT(epoch FROM (first_assignment.first_assigned_date - base.submission_date)) / (60)::numeric) AS minutes_to_assign,
      (EXTRACT(epoch FROM (base.first_decision_date - first_assignment.first_assigned_date)) / (60)::numeric) AS minutes_to_assess
     FROM (base
       JOIN ( SELECT assignment_events.id,
              min(assignment_events.assigned_at) AS first_assigned_date
             FROM assignment_events
            GROUP BY assignment_events.id) first_assignment ON ((base.id = first_assignment.id)));
  SQL
  create_view "submission_by_services", sql_definition: <<-SQL
      SELECT COALESCE((app_ver.application ->> 'service_type'::text), 'not_found'::text) AS service_type,
      date_trunc('DAY'::text, app.created_at) AS date_submitted,
      count(*) AS submissions
     FROM (application app
       JOIN application_version app_ver ON (((app.id = app_ver.application_id) AND (app_ver.version = 1) AND (app_ver.pending IS FALSE))))
    WHERE (app.application_type = 'crm4'::text)
    GROUP BY COALESCE((app_ver.application ->> 'service_type'::text), 'not_found'::text), (date_trunc('DAY'::text, app.created_at));
  SQL
  create_view "submission_creation_times", sql_definition: <<-SQL
      WITH base AS (
           SELECT DISTINCT app_ver.application_id,
              application.application_type,
              ((app_ver.application ->> 'created_at'::text))::timestamp without time zone AS draft_created_date,
              (app_ver.application ->> 'office_code'::text) AS office_code,
              application_submissions.submission_date,
                  CASE
                      WHEN (((app_ver.application ->> 'import_date'::text))::timestamp without time zone IS NOT NULL) THEN true
                      ELSE false
                  END AS claim_imported
             FROM ((application_version app_ver
               JOIN ( SELECT application_version.application_id,
                      min(application_version.created_at) AS submission_date
                     FROM application_version
                    WHERE ((application_version.application ->> 'status'::text) = 'submitted'::text)
                    GROUP BY application_version.application_id) application_submissions ON ((app_ver.application_id = application_submissions.application_id)))
               JOIN application ON ((app_ver.application_id = application.id)))
            WHERE ((app_ver.application ->> 'status'::text) = 'submitted'::text)
          )
   SELECT base.application_id,
      base.application_type,
      base.draft_created_date,
      base.office_code,
      base.submission_date,
      base.claim_imported,
      (EXTRACT(epoch FROM (base.submission_date - base.draft_created_date)) / (60)::numeric) AS minutes_to_submit
     FROM base;
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
               LEFT JOIN application a ON (((a.id = av.application_id) AND (av.pending IS FALSE))))
            GROUP BY a.application_type, ((av.created_at)::date)
            ORDER BY a.application_type, ((av.created_at)::date)) counted_values;
  SQL
end
