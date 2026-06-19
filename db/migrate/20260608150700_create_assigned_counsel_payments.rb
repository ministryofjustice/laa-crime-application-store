class CreateAssignedCounselPayments < ActiveRecord::Migration[8.1]
  def change
    create_view :assigned_counsel_payments
  end
end
