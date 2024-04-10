require 'pond'
require 'que'
require 'pg'
require 'httparty'
require_relative './notify_subscriber_job'

unless ENV['ENV'] == 'production'
  require 'dotenv/load'
  require 'byebug'

  Dotenv.load ".env"
end

Que.connection = Pond.new(maximum_size: 10) do
  PG::Connection.open(
    host: ENV['POSTGRES_HOSTNAME'],
    user: ENV['POSTGRES_USERNAME'],
    password: ENV['POSTGRES_PASSWORD'],
    port: ENV['POSTGRES_PORT'] || 5432,
    dbname: ENV['POSTGRES_NAME']
  )
end
