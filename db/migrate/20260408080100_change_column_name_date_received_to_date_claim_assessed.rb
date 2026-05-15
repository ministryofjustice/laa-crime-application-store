class ChangeColumnNameDateReceivedToDateClaimAssessed < ActiveRecord::Migration[8.1]
  def change
    rename_column :payment_requests, :date_received, :date_claim_assessed
  end
end
