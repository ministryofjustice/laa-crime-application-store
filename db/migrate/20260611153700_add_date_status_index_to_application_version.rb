class AddDateStatusIndexToApplicationVersion < ActiveRecord::Migration[8.1]
  disable_ddl_transaction! #allows concurrently

  INDEX_NAME = "idx_application_version_by_date_on_date_status"

  def up
    return if index_exists_by_name?

    execute <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
      ON application_version (
        (application ->> 'status'),
        (created_at::date),
        application_id
      ) WHERE pending IS FALSE;
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
