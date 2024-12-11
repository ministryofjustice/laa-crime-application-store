class MakeRiskOptional < ActiveRecord::Migration[8.0]
  def change
    drop_view :searches, revert_to_version: 7
    change_column :application, :application_risk, :string, null: true
    create_view :searches, version: 7
  end
end
