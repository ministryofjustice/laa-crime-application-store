class AddAssignmentFieldsToApplication < ActiveRecord::Migration[7.2]
  def up
    add_column :application, :assigned_user_id, :string
    add_column :application, :unassigned_user_ids, :string, array: true, default: []

    Submission.find_each do |submission|
      ass_and_unass_events = submission.events.select { _1['event_type'].in?(%w[assignment unassignment send_back]) }
                                       .sort_by { DateTime.parse(_1['created_at']) }
      last_event = ass_and_unass_events.last

      if last_event['event_type'] == 'assignment'
        assigned_user_id = last_event['primary_user_id']
      end

      unassigned_user_ids = ass_and_unass_events.map { _1['primary_user_id'] }.compact.uniq - [assigned_user_id]

      submission.update!(assigned_user_id:, unassigned_user_ids:)
    end
  end

  def down
    remove_column :application, :assigned_user_id, :string
    remove_column :application, :unassigned_user_ids, :string, array: true, default: []
  end
end
