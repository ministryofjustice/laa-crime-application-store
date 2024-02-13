Rails.application.routes.draw do
  namespace "v1" do
    resources :submissions, only: %i[show create index] do
      collection do
        post :assignments, to: "submissions#create_assignment"
      end

      member do
        delete :assignment, to: "submissions#delete_assignment"
        post :adjustments, to: "submissions#create_adjustment"
        post :risk_changes, to: "submissions#change_risk"
        post :notes, to: "submissions#create_note"
        post :state_changes, to: "submissions#change_state"
      end
    end

    # Legacy endpoint aliases
    get :applications, to: "submissions#index"
    post :application, to: "submissions#create"
    get "application/:id", to: "submissions#show"
    put "application/:id", to: "submissions#create_adjustment"
  end

  root to: "v1/submissions#index"
end
