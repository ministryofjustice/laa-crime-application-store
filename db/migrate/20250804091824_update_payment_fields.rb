class UpdatePaymentFields < ActiveRecord::Migration[8.0]
  def change
    rename_column :nsm_claims, :client_surname, :client_last_name
    rename_column :nsm_claims, :case_concluded_date, :work_completed_date
    add_column :nsm_claims, :client_first_name, :string
    add_column :nsm_claims, :outcome_code, :string
    add_column :nsm_claims, :matter_type, :string
    add_column :nsm_claims, :youth_court, :boolean

    add_column :assigned_counsel_claims, :date_received, :datetime
    add_column :assigned_counsel_claims, :ufn, :string
    add_column :assigned_counsel_claims, :solicitor_office_code, :string
    add_column :assigned_counsel_claims, :client_last_name, :string

    add_column :payment_requests, :date_claim_received, :datetime
  end
end
