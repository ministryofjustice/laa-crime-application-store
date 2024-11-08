require "sidekiq/web"

# Configure Sidekiq-specific session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use Rails.application.config.session_store, Rails.application.config.session_options

Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://web.archive.org/web/20180709235757/https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_WEB_UI_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_WEB_UI_PASSWORD"]))
  end
  mount Sidekiq::Web => "/sidekiq"

  namespace "v1" do
    resources :submissions, only: %i[show create index update] do
      resources :events, only: %i[create]
      resource :assignment, only: %i[create destroy]
      member { patch :metadata }
    end
    resources :subscribers, only: %i[create]
    delete :subscribers, to: "subscribers#destroy"

    namespace :submissions do
      resource :searches, only: %[create]
    end

    # Legacy endpoint aliases
    get :applications, to: "submissions#index"
    post :application, to: "submissions#create"
    get "application/:id", to: "submissions#show"
    put "application/:id", to: "submissions#update"
    post :subscriber, to: "subscribers#create"
    delete :subscriber, to: "subscribers#destroy"
  end

  root to: "v1/submissions#index"
  get :ping, to: "health#show"
end
