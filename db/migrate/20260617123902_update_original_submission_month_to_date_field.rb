class UpdateOriginalSubmissionMonthToDateField < ActiveRecord::Migration[8.1]
  def change
    remove_column :payable_claims, :original_submission_month, :integer
    remove_column :payable_claims, :original_submission_year, :integer
    add_column :payable_claims, :original_submission_date, :date
  end
end
