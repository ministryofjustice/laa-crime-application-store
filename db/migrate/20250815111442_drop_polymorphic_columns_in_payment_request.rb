class DropPolymorphicColumnsInPaymentRequest < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        remove_column :payment_requests, :payable_id, :string
        remove_column :payment_requests, :payable_type, :string
      end

      dir.down do
        add_column :payment_requests, :payable_id, :string
        add_column :payment_requests, :payable_type, :string
        add_index  :payment_requests, [:payable_type, :payable_id]
      end
    end
  end
end
