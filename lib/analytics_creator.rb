class AnalyticsCreator
  SCHEMA = "public".freeze
  NON_VIEW_TABLES = %w[failed_imports].freeze
  attr_reader :username, :password, :database_name

  class << self
    def run
      creator = AnalyticsCreator.new(
        username: ENV.fetch("ANALYTICS_USERNAME"),
        password: ENV.fetch("ANALYTICS_PASSWORD"),
      )
      creator.run
    end

    def drop_user
      creator = AnalyticsCreator.new(
        username: ENV.fetch("ANALYTICS_USERNAME"),
        password: ENV.fetch("ANALYTICS_PASSWORD"),
      )
      creator.drop_user
    end
  end

  def initialize(username:, password:, database_name: nil)
    @username = username
    @password = password
    @database_name = database_name || ActiveRecord::Base.connection_db_config.database
  end

  def run
    create_user
    apply_permissions
  end

  def drop_user
    roles = execute("select * from pg_catalog.pg_roles where rolname='#{username}'")
    return unless roles.rows.any?

    execute("REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA #{SCHEMA} FROM #{username};")
    execute("REVOKE USAGE ON SCHEMA #{SCHEMA} FROM #{username}")
    execute("ALTER DEFAULT PRIVILEGES IN SCHEMA #{SCHEMA} REVOKE ALL ON TABLES FROM #{username}")
    execute("REVOKE CONNECT ON DATABASE #{database_name} FROM #{username}")
    execute("DROP ROLE #{username}")
  end

private

  def create_user
    raise "ANALYTICS_PASSWORD must be set." if password.blank?

    roles = execute("select * from pg_catalog.pg_roles where rolname='#{username}'")

    return if roles.rows.any?

    execute("CREATE ROLE #{username} WITH LOGIN PASSWORD '#{password}'")
    execute("GRANT CONNECT ON DATABASE #{database_name} TO #{username}")
    execute("GRANT USAGE ON SCHEMA #{SCHEMA} TO #{username}")
  end

  def apply_permissions
    NON_VIEW_TABLES.each do |table_name|
      execute("GRANT SELECT ON #{table_name} TO #{username}")
    end

    Scenic.database.views.each do |view|
      execute("GRANT SELECT ON #{view.name} TO #{username}")
    end
  end

  def execute(sql)
    ActiveRecord::Base.connection.exec_query(sql)
  end
end
