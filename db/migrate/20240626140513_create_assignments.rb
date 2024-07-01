class CreateAssignments < ActiveRecord::Migration[7.1]
  def change
    create_view :eod_assignment_count
  end
end
