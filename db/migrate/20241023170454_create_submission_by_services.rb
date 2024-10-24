class CreateSubmissionByServices < ActiveRecord::Migration[7.2]
  def change
    create_view :submission_by_services
  end
end
