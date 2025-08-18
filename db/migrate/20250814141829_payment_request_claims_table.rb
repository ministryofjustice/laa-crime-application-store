class PaymentRequestClaimsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_request_claims, id: :uuid do |t|
      t.string   :type
      t.string   :firm_name
      t.string   :office_code
      t.string   :stage_code
      t.datetime :work_completed_date
      t.string   :court_name
      t.integer  :court_attendances
      t.integer  :no_of_defendants
      t.string   :client_first_name
      t.string   :outcome_code
      t.string   :matter_type
      t.boolean  :youth_court
      t.string   :laa_reference
      t.string   :ufn
      t.datetime :date_received
      t.string   :client_last_name
      t.uuid     :nsm_claim_id
      t.string   :solicitor_office_code

      t.timestamps
    end

    add_foreign_key :payment_request_claims, :payment_request_claims, column: :nsm_claim_id
    add_index :payment_request_claims, :type
    add_index :payment_request_claims, :client_last_name
    add_index :payment_request_claims, :laa_reference
    add_index :payment_request_claims, :office_code
    add_index :payment_request_claims, :ufn
    add_index :payment_request_claims, :date_received
  end
end
