class AddPaymentRequest < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_requests, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "submitter_id"
      t.string "type"
      t.decimal "profit_cost", precision: 10, scale: 2
      t.decimal "travel_cost", precision: 10, scale: 2
      t.decimal "waiting_cost", precision: 10, scale: 2
      t.decimal "disbursement_cost", precision: 10, scale: 2
      t.decimal "disbursement_vat", precision: 10, scale: 2
      t.decimal "assigned_counsel_cost", precision: 10, scale: 2
      t.decimal "assigned_counsel_vat", precision: 10, scale: 2
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
