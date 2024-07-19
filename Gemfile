source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").strip

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.3"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem "httparty"
gem "jwt", "~> 2.8.2"
gem "lograge"
gem "logstash-event"
gem "oauth2"
gem "prometheus_exporter"
gem "scenic"
gem "sentry-rails", ">= 5.17.2"
gem "sentry-ruby"
gem "sidekiq", "~> 7.3"
gem "sidekiq_alive", "~> 2.4"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails"
  gem "factory_bot_rails", ">= 6.2.0"
  gem "pry-nav"
  gem "pry-rescue"
  gem "pry-stack_explorer"
  gem "rspec-rails"

  gem "rubocop-govuk", require: false
  gem "rubocop-performance"
  gem "simplecov", require: false
end

group :test do
  gem "rspec_junit_formatter"
  gem "webmock", ">= 3.13.0"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
