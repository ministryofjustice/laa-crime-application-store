module V1
  class SubmissionsController < ApplicationController
    before_action :authenticate!

    def index
      applications = Submissions::ListService.call(params)
      render json: { applications: }
    end

    def create
      Submissions::CreationService.call(params)
      head :created
    rescue Submissions::CreationService::AlreadyExistsError
      head :conflict
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def show
      render json: Submission.find(params[:id])
    end

    def update
      Submissions::UpdateService.call(params)
      head :created
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end
  end
end
