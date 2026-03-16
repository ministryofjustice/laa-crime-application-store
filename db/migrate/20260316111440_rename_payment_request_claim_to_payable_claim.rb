class RenamePaymentRequestClaimToPayableClaim < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :payment_requests, :payment_request_claims

    rename_table :payment_request_claims, :payable_claims
    rename_column :payment_requests, :payment_request_claim_id, :payable_claim_id
    if index_name_exists?(:payment_requests, "index_payment_requests_on_payment_request_claim_id") &&
       !index_name_exists?(:payment_requests, "index_payment_requests_on_payable_claim_id")
      rename_index :payment_requests,
                   "index_payment_requests_on_payment_request_claim_id",
                   "index_payment_requests_on_payable_claim_id"
    end

    add_foreign_key :payment_requests, :payable_claims, column: :payable_claim_id
  end

  def down
    remove_foreign_key :payment_requests, :payable_claims, column: :payable_claim_id

    if index_name_exists?(:payment_requests, "index_payment_requests_on_payable_claim_id") &&
       !index_name_exists?(:payment_requests, "index_payment_requests_on_payment_request_claim_id")
      rename_index :payment_requests,
                   "index_payment_requests_on_payable_claim_id",
                   "index_payment_requests_on_payment_request_claim_id"
    end
    rename_column :payment_requests, :payable_claim_id, :payment_request_claim_id
    rename_table :payable_claims, :payment_request_claims

    add_foreign_key :payment_requests, :payment_request_claims
  end
end
