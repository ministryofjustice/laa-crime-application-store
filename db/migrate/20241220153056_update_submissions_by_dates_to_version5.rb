class UpdateSubmissionsByDatesToVersion5 < ActiveRecord::Migration[8.0]
  def change
    update_view :submissions_by_date, version: 5, revert_to_version: 4
  end
end
