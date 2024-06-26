class CreateSubmissionsByDates < ActiveRecord::Migration[7.1]
  def change
    create_view :submissions_by_dates
  end
end
