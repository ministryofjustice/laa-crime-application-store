class AddPaymentRequest < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_requests, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "submitter_id", null: false
      t.string "laa_reference"
      t.string "ufn"
      t.string "type"
      t.string "firm_name"
      t.string "office_code"
      t.string "stage_code"
      t.string "client_surname"
      t.datetime "case_concluded_date"
      t.string "court_name"
      t.integer "court_attendances"
      t.integer "no_of_defendants"
      t.decimal "profit_cost", precision: 10, scale: 2
      t.decimal "travel_cost", precision: 10, scale: 2
      t.decimal "waiting_cost", precision: 10, scale: 2
      t.decimal "disbursement_cost", precision: 10, scale: 2
      t.decimal "disbursement_vat", precision: 10, scale: 2
      t.decimal "allowed_profit_cost", precision: 10, scale: 2
      t.decimal "allowed_travel_cost", precision: 10, scale: 2
      t.decimal "allowed_waiting_cost", precision: 10, scale: 2
      t.decimal "allowed_disbursement_cost", precision: 10, scale: 2
      t.decimal "allowed_disbursement_vat", precision: 10, scale: 2
      t.datetime "submitted_at"
      t.timestamps
    end
  end
end
