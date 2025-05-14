class CreateSubmissionAssessTimes < ActiveRecord::Migration[8.0]
  def change
    create_view :submission_assess_times
  end
end
