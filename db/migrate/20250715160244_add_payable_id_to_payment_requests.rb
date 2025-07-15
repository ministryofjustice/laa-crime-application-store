class AddPayableIdToPaymentRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_requests, :payable_id, :string
    add_column :payment_requests, :payable_type, :string
  end
end
