class PrependCostsWithClaimedOnPaymentRequets < ActiveRecord::Migration[8.1]
  def change
    rename_column :payment_requests, :travel_cost, :claimed_travel_cost
    rename_column :payment_requests, :waiting_cost, :claimed_waiting_cost
    rename_column :payment_requests, :disbursement_cost, :claimed_disbursement_cost
    rename_column :payment_requests, :profit_cost, :claimed_profit_cost
    rename_column :payment_requests, :assigned_counsel_vat, :claimed_assigned_counsel_vat
    rename_column :payment_requests, :net_assigned_counsel_cost, :claimed_net_assigned_counsel_cost
  end
end
