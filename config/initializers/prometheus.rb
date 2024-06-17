# The below is heavily cribbed from ministryofjustice/laa-apply-for-criminal-legal-aid
return unless ENV.fetch("ENABLE_PROMETHEUS_EXPORTER", "false") == "true"

require "prometheus_exporter/server"

DEFAULT_PREFIX = "ruby_".freeze

# We are running puma in single process mode, so this is safe
# If we move to multi process mode, we will have to run the
# exporter process separately (`bundle exec prometheus_exporter`)
def start_prometheus_server
  server = PrometheusExporter::Server::WebServer.new(
    bind: "0.0.0.0", port: ENV.fetch("PROMETHEUS_EXPORTER_PORT", 9394).to_i,
    verbose: ENV.fetch("PROMETHEUS_EXPORTER_VERBOSE", "false") == "true"
  )

  server.start

  true
rescue Errno::EADDRINUSE
  warn "[PrometheusExporter] Server port already in use."
  false
end

return unless start_prometheus_server

require "prometheus_exporter/instrumentation"
require "prometheus_exporter/middleware"

Rails.logger.info "[PrometheusExporter] Initialising instrumentation middleware..."

# Metrics will be prefixed, for example `ruby_http_requests_total`
PrometheusExporter::Metric::Base.default_prefix = DEFAULT_PREFIX

# This reports stats per request like HTTP status and timings
Rails.application.middleware.unshift PrometheusExporter::Middleware

# This reports basic process stats like RSS and GC info, type master
# means it is instrumenting the master process
PrometheusExporter::Instrumentation::Process.start(type: "master")

# NOTE: if running Puma in cluster mode, the following
# instrumentation will need to be changed
PrometheusExporter::Instrumentation::Puma.start unless PrometheusExporter::Instrumentation::Puma.started?
PrometheusExporter::Instrumentation::ActiveRecord.start
