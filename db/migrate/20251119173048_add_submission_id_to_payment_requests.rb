class AddSubmissionIdToPaymentRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_requests, :submission_id, :uuid
  end
end
