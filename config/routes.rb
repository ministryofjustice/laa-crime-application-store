Rails.application.routes.draw do
  namespace "v1" do
    resources :submissions, only: %i[show create index update]
    resources :subscribers, only: %i[create]
    delete :subscribers, to: "subscribers#destroy"

    # Legacy endpoint aliases
    get :applications, to: "submissions#index"
    post :application, to: "submissions#create"
    get "application/:id", to: "submissions#show"
    put "application/:id", to: "submissions#update"
    post :subscriber, to: "subscribers#create"
    delete :subscriber, to: "subscribers#destroy"
  end

  root to: "v1/submissions#index"
end
