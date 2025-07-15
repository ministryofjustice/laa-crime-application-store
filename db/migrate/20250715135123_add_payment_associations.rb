class AddPaymentAssociations < ActiveRecord::Migration[8.0]
  def change
    change_table :payment_requests do |t|
      t.belongs_to :nsm_claim
      t.belongs_to :assigned_counsel_claim, type: :uuid, index: { unique: true }, foreign_key: true
    end

    change_table :assigned_counsel_claims do |t|
      t.belongs_to :nsm_claim
    end
  end
end
