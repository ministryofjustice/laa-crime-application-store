class AddAssignmentColumnsToSubmissions < ActiveRecord::Migration[7.0]
  def change
    change_table :submissions, bulk: true do |t|
      t.string :assigned_user_id
      t.jsonb :unassigned_user_ids, default: []
    end
  end
end
