class DropAssignedCounselClaimsAndNsmClaims < ActiveRecord::Migration[8.0]
 def up
    drop_table :assigned_counsel_claims
    drop_table :nsm_claims
  end

  def down
    create_table "nsm_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "laa_reference"
      t.string "ufn"
      t.datetime "date_received"
      t.string "firm_name"
      t.string "office_code"
      t.string "stage_code"
      t.string "client_last_name"
      t.datetime "work_completed_date"
      t.string "court_name"
      t.integer "court_attendances"
      t.integer "no_of_defendants"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "client_first_name"
      t.string "outcome_code"
      t.string "matter_type"
      t.boolean "youth_court"
    end

    create_table "assigned_counsel_claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "laa_reference"
      t.string "counsel_office_code"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.uuid "nsm_claim_id"
      t.datetime "date_received"
      t.string "ufn"
      t.string "solicitor_office_code"
      t.string "client_last_name"

      t.index ["nsm_claim_id"], name: "index_assigned_counsel_claims_on_nsm_claim_id", unique: true
    end

    add_foreign_key :assigned_counsel_claims, :nsm_claims, column: :nsm_claim_id
  end
end
