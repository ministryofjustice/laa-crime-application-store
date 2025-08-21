return if ENV["CI"]
return if ENV["NOFW"]

ENV["PGGSSENCMODE"] = "disable"

Flatware.configure do |conf|
  conf.before_fork do
    require "rails_helper"

    ActiveRecord::Base.connection.disconnect!
  end

  conf.after_fork do |test_env_number|
    SimpleCov.at_fork.call(test_env_number)

    config = ActiveRecord::Base.connection_db_config.configuration_hash

    ActiveRecord::Base.establish_connection(
      config.merge(
        database: config.fetch(:database) + test_env_number.to_s,
      ),
    )
  end
end
