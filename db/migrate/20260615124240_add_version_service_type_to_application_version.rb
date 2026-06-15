class AddVersionServiceTypeToApplicationVersion < ActiveRecord::Migration[8.1]
  disable_ddl_transaction! #allows concurrently

  INDEX_NAME = "idx_application_version_service_type_pending"

  def up
    return if index_exists_by_name?

    execute <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON 
      application_version (
        application_id,
        (application ->> 'service_type'),
        DATE_TRUNC('DAY', created_at)
      )
    SQL
  end

  def down
    return unless index_exists_by_name?

    execute <<~SQL
      DROP INDEX CONCURRENTLY #{INDEX_NAME};
    SQL
  end

  private

  def index_exists_by_name?
    ActiveRecord::Base.connection.indexes(:application_version)
      .any? { |idx| idx.name == INDEX_NAME }
  end
end
