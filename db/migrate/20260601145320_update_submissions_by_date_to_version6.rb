class UpdateSubmissionsByDateToVersion6 < ActiveRecord::Migration[8.1]
  def change
    update_view :submissions_by_date, version: 6, revert_to_version: 5
  end
end
