class MakeStateColumnConsistent < ActiveRecord::Migration[7.2]
  def change
    rename_column :application, :application_state, :state

    update_view :searches, version: 5, revert_to_version: 4
  end
end
