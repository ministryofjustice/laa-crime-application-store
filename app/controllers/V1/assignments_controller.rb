module V1
  class AssignmentsController < ApplicationController
    def create
      current_submission.with_lock do
        current_submission.assigned_user_id = params[:caseworker_id]
        current_submission.save!
      end
      head :created
    end

    def destroy
      current_submission.with_lock do
        # `unassigned_user_ids allows us to log which caseworkers have ever been
        # assigned to a claim, both for search filtering and to allow us to run
        # automatic assignment logic
        current_submission.unassigned_user_ids << current_submission.assigned_user_id
        current_submission.assigned_user_id = nil
        current_submission.save!
      end
      head :no_content
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
