class CreateNsmPayments < ActiveRecord::Migration[8.1]
  def change
    create_view :nsm_payments
  end
end
