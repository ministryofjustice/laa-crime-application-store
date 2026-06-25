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

ActiveRecord::Schema[8.1].define(version: 2026_06_24_094444) do
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
    t.index ["application_type", "last_updated_at"], name: "idx_application_on_type_last_updated_at"
    t.index ["application_type"], name: "idx_application_type"
    t.index ["application_type"], name: "idx_application_version_type"
    t.index ["id", "current_version"], name: "idx_application_auto_grant_current_version", where: "(state = 'auto_grant'::text)"
  end

  add_check_constraint "application", "created_at IS NOT NULL", name: "application_created_at_null", validate: false
  add_check_constraint "application", "updated_at IS NOT NULL", name: "application_updated_at_null", validate: false

  create_table "application_version", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "application", null: false
    t.uuid "application_id", null: false
    t.datetime "created_at", precision: nil
    t.integer "json_schema_version", null: false
    t.boolean "pending", default: false
    t.virtual "search_fields", type: :tsvector, as: "((((((setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'defendant'::text) ->> 'first_name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\") || setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'defendant'::text) ->> 'last_name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (replace((jsonb_path_query_array(application, '$.\"defendants\"[*].\"first_name\"'::jsonpath))::text, '/'::text, '-'::text))::jsonb), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, (replace((jsonb_path_query_array(application, '$.\"defendants\"[*].\"last_name\"'::jsonpath))::text, '/'::text, '-'::text))::jsonb), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, replace(COALESCE(((application -> 'firm_office'::text) ->> 'name'::text), ''::text), '/'::text, '-'::text)), 'B'::\"char\")) || setweight(to_tsvector('simple'::regconfig, COALESCE((application ->> 'ufn'::text), ''::text)), 'A'::\"char\")) || setweight(to_tsvector('simple'::regconfig, replace(lower(COALESCE((application ->> 'laa_reference'::text), ''::text)), '-'::text, ''::text)), 'A'::\"char\"))", stored: true
    t.datetime "updated_at", precision: nil
    t.integer "version", null: false
    t.index "(((application -> 'firm_office'::text) ->> 'account_number'::text))", name: "idx_application_version_on_account_number"
    t.index "((application ->> 'laa_reference'::text))", name: "idx_application_version_on_laa_reference"
    t.index "((application ->> 'status'::text)), ((created_at)::date), application_id", name: "idx_application_version_by_date_on_date_status", where: "(pending IS FALSE)"
    t.index ["application_id", "created_at"], name: "idx_app_ver_final_status_first_decision", where: "((application ->> 'status'::text) = ANY (ARRAY['rejected'::text, 'part_grant'::text, 'granted'::text]))"
    t.index ["application_id", "version"], name: "idx_application_versions_app_id_version"
    t.index ["search_fields"], name: "index_application_version_on_search_fields", using: :gin
  end

  create_table "failed_imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "details"
    t.string "error_type"
    t.uuid "provider_id", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payable_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "client_first_name"
    t.string "client_last_name"
    t.string "counsel_firm_name"
    t.string "counsel_office_code"
    t.integer "court_attendances"
    t.string "court_id"
    t.string "court_name"
    t.datetime "created_at", null: false
    t.uuid "idempotency_token"
    t.string "laa_reference"
    t.string "matter_type"
    t.integer "no_of_defendants"
    t.uuid "nsm_claim_id"
    t.date "original_submission_date"
    t.string "outcome_code"
    t.string "solicitor_firm_name"
    t.string "solicitor_office_code"
    t.string "stage_code"
    t.uuid "submission_id"
    t.string "type"
    t.string "ufn"
    t.datetime "updated_at", null: false
    t.datetime "work_completed_date"
    t.boolean "youth_court"
    t.index "lower((client_last_name)::text) gin_trgm_ops", name: "idx_pc_client_last_name_trgm", using: :gin
    t.index "lower((laa_reference)::text)", name: "idx_pc_lower_laa_reference"
    t.index "lower((solicitor_firm_name)::text) gin_trgm_ops", name: "idx_pc_solicitor_firm_name_trgm", using: :gin
    t.index "lower((solicitor_office_code)::text)", name: "idx_pc_lower_solicitor_office_code"
    t.index ["client_last_name"], name: "index_payable_claims_on_client_last_name"
    t.index ["idempotency_token"], name: "index_payable_claims_on_idempotency_token", unique: true
    t.index ["laa_reference"], name: "index_payable_claims_on_laa_reference"
    t.index ["solicitor_office_code"], name: "index_payable_claims_on_solicitor_office_code"
    t.index ["submission_id"], name: "idx_pc_submission_id"
    t.index ["type"], name: "index_payable_claims_on_type"
    t.index ["ufn"], name: "index_payable_claims_on_ufn"
  end

  create_table "payment_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "allowed_assigned_counsel_vat", precision: 10, scale: 2
    t.decimal "allowed_disbursement_cost", precision: 10, scale: 2
    t.decimal "allowed_net_assigned_counsel_cost", precision: 10, scale: 2
    t.decimal "allowed_profit_cost", precision: 10, scale: 2
    t.decimal "allowed_total", precision: 10, scale: 2
    t.decimal "allowed_travel_cost", precision: 10, scale: 2
    t.decimal "allowed_waiting_cost", precision: 10, scale: 2
    t.decimal "claimed_assigned_counsel_vat", precision: 10, scale: 2
    t.decimal "claimed_disbursement_cost", precision: 10, scale: 2
    t.decimal "claimed_net_assigned_counsel_cost", precision: 10, scale: 2
    t.decimal "claimed_profit_cost", precision: 10, scale: 2
    t.decimal "claimed_total", precision: 10, scale: 2
    t.decimal "claimed_travel_cost", precision: 10, scale: 2
    t.decimal "claimed_waiting_cost", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "date_claim_assessed"
    t.uuid "payable_claim_id"
    t.string "request_type"
    t.datetime "submitted_at"
    t.uuid "submitter_id"
    t.datetime "updated_at", null: false
    t.index ["date_claim_assessed"], name: "idx_pr_date_claim_assessed"
    t.index ["payable_claim_id"], name: "index_payment_requests_on_payable_claim_id"
    t.index ["request_type", "date_claim_assessed"], name: "idx_pr_request_type_date_assessed"
    t.index ["request_type", "submitted_at"], name: "idx_pr_request_type_submitted_at", order: { submitted_at: :desc }
    t.index ["request_type"], name: "index_payment_requests_on_request_type"
    t.index ["submitted_at"], name: "idx_pr_submitted_at_desc", order: :desc
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
  add_foreign_key "payable_claims", "payable_claims", column: "nsm_claim_id"
  add_foreign_key "payment_requests", "payable_claims"

  create_view "active_providers", sql_definition: <<-SQL
      WITH submissions AS (
           SELECT application.application_type,
              (application_version.application -> 'office_code'::text) AS office_code,
              date_trunc('week'::text, application_version.created_at) AS submitted_start
             FROM (application_version
               JOIN application ON ((application_version.application_id = application.id)))
            WHERE (application_version.version = 1)
            GROUP BY application.application_type, (application_version.application -> 'office_code'::text), (date_trunc('week'::text, application_version.created_at))
          ), weekly_submissions AS (
           SELECT submissions.application_type,
              submissions.submitted_start,
              count(DISTINCT submissions.office_code) AS office_codes_submitting_during_the_period,
              jsonb_agg(DISTINCT submissions.office_code) AS office_codes_during_the_period
             FROM submissions
            GROUP BY submissions.application_type, submissions.submitted_start
          ), first_submission_weeks AS (
           SELECT submissions.application_type,
              submissions.office_code,
              min(submissions.submitted_start) AS submitted_start
             FROM submissions
            WHERE (submissions.office_code IS NOT NULL)
            GROUP BY submissions.application_type, submissions.office_code
          ), provider_growth_by_week AS (
           SELECT first_submission_weeks.application_type,
              first_submission_weeks.submitted_start,
              count(*) AS new_office_codes
             FROM first_submission_weeks
            GROUP BY first_submission_weeks.application_type, first_submission_weeks.submitted_start
          ), cumulative_counts AS (
           SELECT weekly_submissions_1.application_type,
              weekly_submissions_1.submitted_start,
              sum(COALESCE(provider_growth_by_week.new_office_codes, (0)::bigint)) OVER (PARTITION BY weekly_submissions_1.application_type ORDER BY weekly_submissions_1.submitted_start ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_office_codes_submitters
             FROM (weekly_submissions weekly_submissions_1
               LEFT JOIN provider_growth_by_week ON (((provider_growth_by_week.application_type = weekly_submissions_1.application_type) AND (provider_growth_by_week.submitted_start = weekly_submissions_1.submitted_start))))
          )
   SELECT weekly_submissions.application_type AS application_type,
      weekly_submissions.submitted_start AS submitted_start,
      weekly_submissions.office_codes_submitting_during_the_period AS office_codes_submitting_during_the_period,
      cumulative_counts.total_office_codes_submitters AS total_office_codes_submitters,
      weekly_submissions.office_codes_during_the_period AS office_codes_during_the_period
     FROM (weekly_submissions
       JOIN cumulative_counts ON (((cumulative_counts.application_type = weekly_submissions.application_type) AND (cumulative_counts.submitted_start = weekly_submissions.submitted_start))))
    ORDER BY weekly_submissions.application_type, weekly_submissions.submitted_start;
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
  create_view "assigned_counsel_payments", sql_definition: <<-SQL
      SELECT payment_requests.id AS payment_request_id,
      payable_claims.id AS claim_id,
      payable_claims.laa_reference,
          CASE payment_requests.request_type
              WHEN 'assigned_counsel'::text THEN 'AC'::text
              WHEN 'assigned_counsel_appeal'::text THEN 'AC Appeal'::text
              WHEN 'assigned_counsel_amendment'::text THEN 'AC Amendment'::text
              ELSE NULL::text
          END AS payment_type,
      'CRM8'::text AS description,
      'CL_CON_CWA'::text AS invoice_type,
      NULLIF(TRIM(BOTH FROM concat_ws(' '::text, payable_claims.client_first_name, payable_claims.client_last_name)), ''::text) AS client_name,
      payable_claims.ufn AS case_reference,
      (payment_requests.date_claim_assessed)::date AS date_requested,
      payable_claims.counsel_office_code AS office_code,
      payment_requests.allowed_total AS invoice_amount_inc_vat,
          CASE
              WHEN (COALESCE(payment_requests.allowed_assigned_counsel_vat, payment_requests.claimed_assigned_counsel_vat, (0)::numeric) = (0)::numeric) THEN 0
              ELSE 20
          END AS tax_amount_percentage,
      'Profit costs'::text AS fee_type,
      payable_claims.counsel_firm_name AS provider_reference,
      payment_requests.request_type,
      payment_requests.claimed_net_assigned_counsel_cost,
      payment_requests.claimed_assigned_counsel_vat,
      payment_requests.claimed_total,
      payment_requests.allowed_net_assigned_counsel_cost,
      payment_requests.allowed_assigned_counsel_vat,
      payment_requests.allowed_total,
      payment_requests.date_claim_assessed,
      payment_requests.submitted_at
     FROM (payment_requests
       JOIN payable_claims ON ((payment_requests.payable_claim_id = payable_claims.id)))
    WHERE ((payment_requests.request_type)::text = ANY ((ARRAY['assigned_counsel'::character varying, 'assigned_counsel_appeal'::character varying, 'assigned_counsel_amendment'::character varying])::text[]));
  SQL
  create_view "autogrant_events", sql_definition: <<-SQL
      SELECT a.id,
      av.version AS submission_version,
      (av.created_at)::date AS event_on,
      (av.application ->> 'service_type'::text) AS service_key,
      COALESCE((av.application ->> 'custom_service_name'::text), (t.translation)::text, (av.application ->> 'service_type'::text)) AS service
     FROM ((application a
       JOIN application_version av ON (((av.application_id = a.id) AND (av.version = a.current_version))))
       LEFT JOIN translations t ON ((((t.key)::text = (av.application ->> 'service_type'::text)) AND ((t.translation_type)::text = 'service'::text))))
    WHERE (a.state = 'auto_grant'::text);
  SQL
  create_view "nsm_payments", sql_definition: <<-SQL
      SELECT payable_claims.id AS claim_id,
      payable_claims.court_attendances,
      payable_claims.court_name,
      payable_claims.court_id,
      payable_claims.no_of_defendants,
      payable_claims.outcome_code,
      payable_claims.solicitor_firm_name AS office_name,
      payable_claims.solicitor_office_code AS office_code,
      payable_claims.stage_code,
      payable_claims.ufn,
      payable_claims.laa_reference,
      payable_claims.work_completed_date,
      payable_claims.original_submission_date,
      payable_claims.youth_court,
      payable_claims.client_last_name,
      payment_requests.request_type,
      payment_requests.allowed_disbursement_cost,
      payment_requests.claimed_disbursement_cost,
      payment_requests.allowed_profit_cost,
      payment_requests.claimed_profit_cost,
      payment_requests.allowed_travel_cost,
      payment_requests.claimed_travel_cost,
      payment_requests.allowed_waiting_cost,
      payment_requests.claimed_waiting_cost,
      payment_requests.claimed_total,
      payment_requests.allowed_total,
      payment_requests.date_claim_assessed,
      payment_requests.submitted_at
     FROM (payment_requests
       JOIN payable_claims ON ((payment_requests.payable_claim_id = payable_claims.id)))
    WHERE ((payment_requests.request_type)::text = ANY (ARRAY[('breach_of_injunction'::character varying)::text, ('non_standard_magistrate'::character varying)::text, ('non_standard_mag_supplemental'::character varying)::text, ('non_standard_mag_appeal'::character varying)::text, ('non_standard_mag_amendment'::character varying)::text]));
  SQL
  create_view "processing_times", sql_definition: <<-SQL
      WITH base AS (
           SELECT application.id,
              application.application_type,
              application_version.version,
              COALESCE((previous_application_version.application ->> 'status'::text), 'draft'::text) AS from_status,
              (COALESCE((previous_application_version.application ->> 'updated_at'::text), (application_version.application ->> 'created_at'::text)))::timestamp without time zone AS from_time,
              (application_version.application ->> 'status'::text) AS to_status,
              ((application_version.application ->> 'updated_at'::text))::timestamp without time zone AS to_time,
              (NULLIF((application_version.application ->> 'import_date'::text), ''::text) IS NOT NULL) AS claim_imported
             FROM ((application_version
               JOIN application ON ((application_version.application_id = application.id)))
               LEFT JOIN LATERAL ( SELECT previous_application_version_1.application
                     FROM application_version previous_application_version_1
                    WHERE ((previous_application_version_1.application_id = application_version.application_id) AND (previous_application_version_1.pending IS FALSE) AND (previous_application_version_1.version < application_version.version))
                    ORDER BY previous_application_version_1.version DESC
                   LIMIT 1) previous_application_version ON (true))
            WHERE (application_version.pending IS FALSE)
          )
   SELECT id,
      application_type,
      version,
      from_status,
      from_time,
      to_status,
      to_time,
      claim_imported,
      (from_time)::date AS from_date,
      (to_time)::date AS to_date,
      GREATEST(EXTRACT(epoch FROM (to_time - from_time)), (0)::numeric) AS processing_seconds
     FROM base;
  SQL
  create_view "searches", sql_definition: <<-SQL
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
          CASE
              WHEN (app.application_type = 'crm4'::text) THEN ((((app_ver.application -> 'defendant'::text) ->> 'first_name'::text) || ' '::text) || ((app_ver.application -> 'defendant'::text) ->> 'last_name'::text))
              ELSE ( SELECT (((defendants.value ->> 'first_name'::text) || ' '::text) || (defendants.value ->> 'last_name'::text))
                 FROM jsonb_array_elements((app_ver.application -> 'defendants'::text)) defendants(value)
                WHERE ((defendants.value ->> 'main'::text) = 'true'::text))
          END AS client_name,
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
     FROM (application app
       JOIN application_version app_ver ON (((app.id = app_ver.application_id) AND (app.current_version = app_ver.version))));
  SQL
  create_view "submission_assess_times", sql_definition: <<-SQL
      WITH first_decision AS (
           SELECT DISTINCT ON (application_version.application_id) application_version.application_id,
              application_version.application,
              application_version.created_at AS first_decision_date
             FROM application_version
            WHERE ((application_version.application ->> 'status'::text) = ANY (ARRAY['rejected'::text, 'part_grant'::text, 'granted'::text]))
            ORDER BY application_version.application_id, application_version.created_at
          ), base AS (
           SELECT application.id,
              application.application_type,
              application.created_at AS submission_date,
              (first_decision.application ->> 'status'::text) AS first_decision,
              (first_decision.application ->> 'office_code'::text) AS office_code,
              first_decision.first_decision_date
             FROM (application
               JOIN first_decision ON ((application.id = first_decision.application_id)))
          ), first_assignment AS (
           SELECT base_1.id,
              min(((events.value ->> 'created_at'::text))::timestamp without time zone) AS first_assigned_date
             FROM ((base base_1
               JOIN application ON ((application.id = base_1.id)))
               CROSS JOIN LATERAL jsonb_array_elements(application.caseworker_history_events) events(value))
            WHERE ((events.value ->> 'event_type'::text) = 'assignment'::text)
            GROUP BY base_1.id
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
       JOIN first_assignment ON ((base.id = first_assignment.id)));
  SQL
  create_view "submission_by_services", sql_definition: <<-SQL
      SELECT COALESCE((app_ver.application ->> 'service_type'::text), 'not_found'::text) AS service_type,
      date_trunc('DAY'::text, app_ver.created_at) AS date_submitted,
      count(*) AS submissions
     FROM (application_version app_ver
       JOIN application app ON ((app.id = app_ver.application_id)))
    WHERE ((app.application_type = 'crm4'::text) AND (app_ver.version = 1) AND (app_ver.pending IS FALSE))
    GROUP BY COALESCE((app_ver.application ->> 'service_type'::text), 'not_found'::text), (date_trunc('DAY'::text, app_ver.created_at));
  SQL
  create_view "submission_creation_times", sql_definition: <<-SQL
      WITH first_submissions AS (
           SELECT DISTINCT ON (application_version.application_id) application_version.application_id,
              application_version.application,
              application_version.created_at AS submission_date
             FROM application_version
            WHERE ((application_version.pending IS FALSE) AND ((application_version.application ->> 'status'::text) = 'submitted'::text))
            ORDER BY application_version.application_id, application_version.version
          )
   SELECT first_submissions.application_id,
      application.application_type,
      ((first_submissions.application ->> 'created_at'::text))::timestamp without time zone AS draft_created_date,
      (first_submissions.application ->> 'office_code'::text) AS office_code,
      first_submissions.submission_date,
      (NULLIF((first_submissions.application ->> 'import_date'::text), ''::text) IS NOT NULL) AS claim_imported,
      (EXTRACT(epoch FROM (first_submissions.submission_date - ((first_submissions.application ->> 'created_at'::text))::timestamp without time zone)) / (60)::numeric) AS minutes_to_submit
     FROM (first_submissions
       JOIN application ON ((first_submissions.application_id = application.id)));
  SQL
  create_view "submissions_by_date", sql_definition: <<-SQL
      SELECT (av.created_at)::date AS event_on,
      a.application_type,
      count(*) FILTER (WHERE ((av.application ->> 'status'::text) = 'submitted'::text)) AS submission,
      count(*) FILTER (WHERE ((av.application ->> 'status'::text) = 'provider_updated'::text)) AS resubmission,
      count(*) AS total
     FROM (application_version av
       JOIN application a ON ((a.id = av.application_id)))
    WHERE ((av.pending IS FALSE) AND ((av.application ->> 'status'::text) = ANY (ARRAY['submitted'::text, 'provider_updated'::text])))
    GROUP BY a.application_type, ((av.created_at)::date)
    ORDER BY a.application_type, ((av.created_at)::date);
  SQL
end
