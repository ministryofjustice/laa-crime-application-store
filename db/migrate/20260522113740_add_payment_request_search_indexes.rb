class AddPaymentRequestSearchIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction! # allows concurrently

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pc_lower_laa_reference
      ON payable_claims ((LOWER(laa_reference)));
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pc_lower_solicitor_office_code
      ON payable_claims ((LOWER(solicitor_office_code)));
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pc_submission_id
      ON payable_claims (submission_id);
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pc_client_last_name_trgm
      ON payable_claims USING gin ((LOWER(client_last_name)) gin_trgm_ops);
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pc_solicitor_firm_name_trgm
      ON payable_claims USING gin ((LOWER(solicitor_firm_name)) gin_trgm_ops);
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pr_submitted_at_desc
      ON payment_requests (submitted_at DESC);
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pr_date_claim_assessed
      ON payment_requests (date_claim_assessed);
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pr_request_type_submitted_at
      ON payment_requests (request_type, submitted_at DESC);
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_pr_request_type_date_assessed
      ON payment_requests (request_type, date_claim_assessed);
    SQL
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pr_request_type_date_assessed;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pr_request_type_submitted_at;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pr_date_claim_assessed;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pr_submitted_at_desc;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pc_solicitor_firm_name_trgm;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pc_client_last_name_trgm;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pc_submission_id;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pc_lower_solicitor_office_code;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_pc_lower_laa_reference;"
  end
end
