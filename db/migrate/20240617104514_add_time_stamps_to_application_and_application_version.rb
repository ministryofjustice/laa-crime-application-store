class AddTimeStampsToApplicationAndApplicationVersion < ActiveRecord::Migration[7.1]
  def change
    add_column :application, :created_at, :datetime, precision: nil
    add_column :application_version, :created_at, :datetime, precision: nil
    add_column :application_version, :updated_at, :datetime, precision: nil
  end
end
