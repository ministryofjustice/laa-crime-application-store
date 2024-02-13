module V1
  class SubmissionsController < ApplicationController
    before_action :authenticate!

    def index
      json = SubmissionListService.call(params)
      render json:
    end

    def create
      SubmissionCreationService.call(params)
      head :created
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def show
      render json: Submission.find_by(application_id: params[:id])
    end

    def create_adjustment
      AdjustmentService.call(params)
      head :created
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def create_assignment
      submission = AssignmentService.call(params)
      if submission
        render json: submission, status: :created
      else
        head :not_found
      end
    end

    def delete_assignment
      head UnassignmentService.call(params) ? :ok : :bad_request
    end

    def change_risk
      RiskChangeService.call(params)
      head :ok
    end

    def change_state
      StateChangeService.call(params)
      head :ok
    rescue StandardError
      head :unprocessable_entity
    end

    def create_note
      NoteService.call(params)
      head :created
    end
  end
end
