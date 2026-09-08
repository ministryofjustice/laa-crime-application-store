class ReplaceEnteredTotalWithPayableTotalOnPaymentRequests < ActiveRecord::Migration[8.1]
  def change
    remove_column :payment_requests, :entered_allowed_total, :decimal, precision: 10, scale: 2
    add_column :payment_requests, :payable_total, :decimal, precision: 10, scale: 2
    add_index :payment_requests, :payable_total
  end
end
