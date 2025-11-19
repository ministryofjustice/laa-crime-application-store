module V1
  class AdjustmentsController < ApplicationController
    def create
      ::Submissions::AdjustmentService.call(current_submission, params)
      head :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.message }, status: :unprocessable_content
    end

  private

    def current_submission
      @current_submission ||= Submission.find(params[:submission_id])
    end

    def authorization_object
      current_submission
    end
  end
end
