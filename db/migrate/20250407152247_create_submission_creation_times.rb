class CreateSubmissionCreationTimes < ActiveRecord::Migration[8.0]
  def change
    create_view :submission_creation_times
  end
end
