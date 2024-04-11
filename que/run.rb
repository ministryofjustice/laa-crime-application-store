require "pond"
require "que"
require "pg"
require "httparty"
require "sentry"
require_relative "./notify_subscriber_job"

unless ENV["ENV"] == "production"
  require "dotenv/load"
  require "byebug"

  Dotenv.load ".env"
end

if ENV["SENTRY_DSN"]
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
  end
end

Que.connection = Pond.new(maximum_size: 10) do
  PG::Connection.open(
    host: ENV["POSTGRES_HOSTNAME"],
    user: ENV["POSTGRES_USERNAME"],
    password: ENV["POSTGRES_PASSWORD"],
    port: ENV["POSTGRES_PORT"] || 5432,
    dbname: ENV["POSTGRES_NAME"],
  )
end

Que.error_notifier = proc do |error, job_hash|
  Sentry.capture_message(
    "Error processing background job:\n#{error}\n#{job_hash}",
  )
end
