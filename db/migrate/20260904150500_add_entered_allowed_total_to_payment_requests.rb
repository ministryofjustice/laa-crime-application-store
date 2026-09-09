class AddEnteredAllowedTotalToPaymentRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_requests, :entered_allowed_total, :decimal, precision: 10, scale: 2
  end
end
