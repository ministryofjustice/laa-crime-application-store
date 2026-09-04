class AddCalculationMethodToPaymentRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_requests, :calculation_method, :string
    add_index :payment_requests, :calculation_method
  end
end
