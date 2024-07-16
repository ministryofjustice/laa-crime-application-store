class AddLastUpdatedAtToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :application, :last_updated_at, :datetime, precision: nil, if_not_exists: true
  end
end
