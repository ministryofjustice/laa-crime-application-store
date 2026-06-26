class AddColumnNsmClaimTypeToPayableClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :payable_claims, :nsm_claim_type, :string
  end
end
