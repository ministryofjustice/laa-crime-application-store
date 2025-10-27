class RemoveColumnDateClaimReceived < ActiveRecord::Migration[8.1]
  def change
    remove_column :payment_request_claims, :date_received, :datetime
    rename_column :payment_requests, :date_claim_received, :date_received
  end
end
