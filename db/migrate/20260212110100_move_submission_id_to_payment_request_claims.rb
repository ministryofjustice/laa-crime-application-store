class MoveSubmissionIdToPaymentRequestClaims < ActiveRecord::Migration[8.1]
  def up
    add_column :payment_request_claims, :submission_id, :uuid
    remove_column :payment_requests, :submission_id
  end

  def down
    add_column :payment_requests, :submission_id, :uuid
    remove_column :payment_request_claims, :submission_id
  end
end
