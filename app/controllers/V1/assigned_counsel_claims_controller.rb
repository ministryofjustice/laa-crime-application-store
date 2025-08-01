module V1
  class AssignedCounselClaimsController < ApplicationController
    def update
      assigned_counsel_claim.update!(allowed_params)
      render json: assigned_counsel_claim, status: :created
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
      render json: { errors: e.message }, status: :unprocessable_entity
      report_error(e)
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

  private

    def allowed_params
      params.expect(assigned_counsel_claim: [:counsel_office_code])
    end

    def assigned_counsel_claim
      @assigned_counsel_claim ||= AssignedCounselClaim.find(params[:id])
    end
  end
end
