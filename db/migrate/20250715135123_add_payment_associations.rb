class AddPaymentAssociations < ActiveRecord::Migration[8.0]
  def change
    change_table :payment_requests do |t|
      t.string :payable_id
      t.string :payable_type
      t.index [:payable_type, :payable_id]
    end

    change_table :assigned_counsel_claims do |t|
      t.belongs_to :nsm_claim, type: :uuid, index: { unique: true }, foreign_key: true
    end
  end
end
