class RemoveIndexesForSubmissionByService < ActiveRecord::Migration[8.1]
  disable_ddl_transaction! #allows concurrently

  def up
    index_names = %w[
      idx_application_version_service_type_pending
      idx_application_version_pending
    ]

    index_names.each do |index_name|
      execute <<~SQL
        DROP INDEX CONCURRENTLY IF EXISTS #{index_name};
      SQL
    end
  end

  def down
    unless index_exists_by_name("idx_application_version_service_type_pending")
      execute <<~SQL
        CREATE INDEX CONCURRENTLY idx_application_version_service_type_pending ON 
        application_version (
          application_id,
          (application ->> 'service_type'),
          DATE_TRUNC('DAY', created_at)
        ) WHERE pending IS FALSE;
      SQL
    end

    unless index_exists_by_name("idx_application_version_pending")
      execute <<~SQL
        CREATE INDEX CONCURRENTLY idx_application_version_pending ON application_version (application_id)
        WHERE version = 1 AND pending IS FALSE;
      SQL
    end
  end


  private

  def index_exists_by_name(index_name)
    ActiveRecord::Base.connection.indexes(:application_version)
      .any? { |idx| idx.name == index_name }
  end
end
