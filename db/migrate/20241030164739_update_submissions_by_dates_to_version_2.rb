class UpdateSubmissionsByDatesToVersion2 < ActiveRecord::Migration[7.2]
  def change
    update_view :submissions_by_date, version: 2, revert_to_version: 1
  end
end
