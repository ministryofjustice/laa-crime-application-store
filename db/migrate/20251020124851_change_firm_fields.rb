class ChangeFirmFields < ActiveRecord::Migration[8.0]
  def change
    rename_column :payment_request_claims, :firm_name, :solicitor_firm_name
    rename_column :payment_request_claims, :solicitor_office_code, :counsel_office_code
    rename_column :payment_request_claims, :office_code, :solicitor_office_code
    add_column :payment_request_claims, :counsel_firm_name, :string
  end
end
