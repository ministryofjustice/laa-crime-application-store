# The below is heavily cribbed from ministryofjustice/laa-apply-for-criminal-legal-aid
return unless ENV.fetch("ENABLE_PROMETHEUS_EXPORTER", "false") == "true"

require "prometheus_exporter/server"
require "prometheus_exporter/instrumentation"
require "prometheus_exporter/middleware"

DEFAULT_PREFIX = "ruby_".freeze
DEFAULT_BIND_ADDRESS = "0.0.0.0".freeze
DEFAULT_PORT = 9394

# We are running puma in single process mode, so this is safe
# If we move to multi process mode, we will have to run the
# exporter process separately (`bundle exec prometheus_exporter`)
def start_prometheus_server
  server = PrometheusExporter::Server::WebServer.new(
    bind: ENV.fetch("PROMETHEUS_EXPORTER_HOST", DEFAULT_BIND_ADDRESS),
    port: ENV.fetch("PROMETHEUS_EXPORTER_PORT", DEFAULT_PORT).to_i,
    verbose: ENV.fetch("PROMETHEUS_EXPORTER_VERBOSE", "false") == "true"
  )

  server.start
  server
rescue Errno::EADDRINUSE
  warn "[PrometheusExporter] Server port already in use."
  false
end

Rails.logger.info("[PrometheusExporter] Starting server....")
server = start_prometheus_server
return unless server

Rails.logger.info("[PrometheusExporter] server started on #{JSON.parse(server.to_json).fetch_values('port', 'bind')}!")
Rails.logger.info("[PrometheusExporter] Initialising standard instrumentation middleware...")

# Metrics will be prefixed, for example `ruby_http_requests_total`
PrometheusExporter::Metric::Base.default_prefix = DEFAULT_PREFIX

# This reports stats per request like HTTP status and timings
Rails.application.middleware.unshift PrometheusExporter::Middleware

# NOTE: if running Puma in cluster mode, the following instrumentation will need to be
# moved to an after_worker_boot block in puma config.
# NOTE: attempting to instrument puma prom export on sidekiq servers will result in lots of error logs
#
unless Sidekiq.server?
  # This reports basic process stats like RSS and GC info, type master
  # means it is instrumenting the master process.
  # see config/puma.rb  after_work_boot for more
  #
  PrometheusExporter::Instrumentation::Process.start(type: "master")

  PrometheusExporter::Instrumentation::Puma.start unless PrometheusExporter::Instrumentation::Puma.started?
  PrometheusExporter::Instrumentation::ActiveRecord.start
end
