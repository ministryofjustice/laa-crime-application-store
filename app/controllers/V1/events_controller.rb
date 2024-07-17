module V1
  class EventsController < ApplicationController
    def create
      ::Submissions::UpdateService.add_events(current_submission, params, save: true)
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
