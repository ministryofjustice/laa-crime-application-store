module V1
  class EventsController < ApplicationController
    def create
      current_submission.with_lock do
        ::Submissions::EventAdditionService.call(current_submission, params)
        current_submission.save!
      end
      head :created
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
