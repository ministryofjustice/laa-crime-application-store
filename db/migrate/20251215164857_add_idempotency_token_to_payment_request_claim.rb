class AddIdempotencyTokenToPaymentRequestClaim < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_request_claims, :idempotency_token, :uuid
    add_index :payment_request_claims, :idempotency_token, unique: true
  end
end
