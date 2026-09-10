class AddPaymentBasisToPaymentRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_requests, :payment_basis, :string
    add_index :payment_requests, :payment_basis
  end
end
