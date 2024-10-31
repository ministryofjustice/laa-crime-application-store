class UpdateSubmissionsByDatesToVersion3 < ActiveRecord::Migration[7.2]
  def change
    update_view :submissions_by_date, version: 3, revert_to_version: 2
  end
end
