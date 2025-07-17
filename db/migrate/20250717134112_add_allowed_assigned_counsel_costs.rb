class AddAllowedAssignedCounselCosts < ActiveRecord::Migration[8.0]
  def change
    change_table :payment_requests do |t|
      t.decimal "allowed_assigned_counsel_cost", precision: 10, scale: 2
      t.decimal "allowed_assigned_counsel_vat", precision: 10, scale: 2
    end
  end
end
