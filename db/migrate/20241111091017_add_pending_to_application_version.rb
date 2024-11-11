class AddPendingToApplicationVersion < ActiveRecord::Migration[7.2]
  def change
    add_column :application_version, :pending, :boolean, default: false
  end
end
