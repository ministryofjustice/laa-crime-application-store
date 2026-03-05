class AddCourtIdToPaymentRequestClaim < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_request_claims, :court_id, :string
  end
end
