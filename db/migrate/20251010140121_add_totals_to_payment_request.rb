class AddTotalsToPaymentRequest < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_requests, :claimed_total, :decimal, precision: 10, scale: 2
    add_column :payment_requests, :allowed_total, :decimal, precision: 10, scale: 2
  end
end
