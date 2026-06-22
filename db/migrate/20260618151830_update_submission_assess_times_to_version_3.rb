class UpdateSubmissionAssessTimesToVersion3 < ActiveRecord::Migration[8.1]
  def change
    update_view :submission_assess_times, version: 3, revert_to_version: 2
  end
end
