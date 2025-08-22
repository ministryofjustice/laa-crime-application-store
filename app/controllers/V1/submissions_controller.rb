module V1
  class SubmissionsController < ApplicationController
    def index
      applications = ::Submissions::ListService.call(params)
      render json: { applications: }
    end

    def show
      render json: current_submission.as_json(client_role: current_client_role)
    end

    def create
      submission = ::Submissions::CreationService.call(params)
      render json: submission, status: :created
    rescue AlreadyExistsError
      head :conflict
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      ::Submissions::UpdateService.call(current_submission, params)
      render json: current_submission, status: :created
    rescue ActiveRecord::RecordInvalid, NoLaaReferenceError => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end

    def metadata
      ::Submissions::MetadataUpdateService.call(current_submission, params)
      head :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end

    def auto_assignments
      submission = ::Submissions::AutoAssignmentService.call(params)
      if submission
        render json: submission, status: :created
      else
        head :not_found
      end
    end

  private

    def current_submission
      @current_submission ||= Submission.find(params[:id])
    end

    def authorization_object
      current_submission if action_name == "update"
    end
  end
end
