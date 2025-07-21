class FixCostFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :payment_requests, :disbursement_vat, :decimal
    remove_column :payment_requests, :allowed_disbursement_vat, :decimal
    rename_column :payment_requests, :assigned_counsel_cost, :net_assigned_counsel_cost
    rename_column :payment_requests, :allowed_assigned_counsel_cost, :allowed_net_assigned_counsel_cost
  end
end
