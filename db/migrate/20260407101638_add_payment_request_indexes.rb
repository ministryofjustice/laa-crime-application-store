class AddPaymentRequestIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index(:payment_requests, :request_type)
  end
end
