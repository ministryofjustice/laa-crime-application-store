class UpdateNsmPaymentsToVersion3 < ActiveRecord::Migration[8.1]
  def change
    update_view :nsm_payments, version: 3, revert_to_version: 2
  end
end
