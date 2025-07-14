class AddRelatedPaymentsToPaymentRequest < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_requests, :related_payments, :string, array: true, default: []
  end
end
