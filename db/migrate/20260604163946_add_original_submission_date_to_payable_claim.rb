class AddOriginalSubmissionDateToPayableClaim < ActiveRecord::Migration[8.1]
  def change
    add_column :payable_claims, :original_submission_year, :integer
    add_column :payable_claims, :original_submission_month, :integer
  end
end
