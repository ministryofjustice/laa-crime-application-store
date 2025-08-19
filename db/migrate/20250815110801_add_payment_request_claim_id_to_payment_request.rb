class AddPaymentRequestClaimIdToPaymentRequest < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_requests, :payment_request_claim_id, :uuid
    add_index  :payment_requests, :payment_request_claim_id
    add_foreign_key :payment_requests, :payment_request_claims
  end
end
