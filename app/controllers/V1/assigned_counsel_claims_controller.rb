module V1
  class AssignedCounselClaimsController < ApplicationController
    def update
      assigned_counsel_claim.update!(permitted_params)
      render json: assigned_counsel_claim, status: :created
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
      render json: { errors: e.message }, status: :unprocessable_entity
      report_error(e)
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

  private

    def permitted_params
      params.permit(
        :counsel_office_code,
        :counsel_firm_name,
        :client_last_name,
        :ufn,
        :solicitor_office_code,
        :solicitor_firm_name,
        :date_received,
      )
    end

    def assigned_counsel_claim
      @assigned_counsel_claim ||= AssignedCounselClaim.find(params[:id])
    end
  end
end
