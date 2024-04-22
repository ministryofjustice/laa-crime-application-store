module V1
  class SubmissionsController < ApplicationController
    def index
      applications = Submissions::ListService.call(params)
      render json: { applications: }
    end

    def create
      Submissions::CreationService.call(params, current_client_role)
      head :created
    rescue Submissions::CreationService::AlreadyExistsError
      head :conflict
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def show
      render json: current_submission
    end

    def update
      Submissions::UpdateService.call(current_submission, params, current_client_role)
      head :created
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def current_submission
      @current_submission ||= Submission.find(params[:id])
    end

    def authorization_object
      current_submission if action_name == "update"
    end
  end
end
