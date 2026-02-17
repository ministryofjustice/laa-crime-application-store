class MoveSubmissionIdToPaymentRequestClaims < ActiveRecord::Migration[8.1]
  def up
    add_column :payment_request_claims, :submission_id, :uuid

    # execute <<~SQL
    #   UPDATE payment_request_claims prc
    #   SET submission_id = pr.submission_id
    #   FROM payment_requests pr
    #   WHERE pr.payment_request_claim_id = prc.id
    #     AND pr.submission_id IS NOT NULL
    #     AND prc.submission_id IS NULL;
    # SQL

    remove_column :payment_requests, :submission_id
  end

  def down
    add_column :payment_requests, :submission_id, :uuid

    # execute <<~SQL
    #   UPDATE payment_requests pr
    #   SET submission_id = prc.submission_id
    #   FROM payment_request_claims prc
    #   WHERE pr.payment_request_claim_id = prc.id
    #     AND prc.submission_id IS NOT NULL;
    # SQL

    remove_column :payment_request_claims, :submission_id
  end
end
