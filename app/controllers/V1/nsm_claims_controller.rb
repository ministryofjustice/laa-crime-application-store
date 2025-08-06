module V1
  class NsmClaimsController < ApplicationController
    def update
      current_nsm_claim.update!(allowed_params)
      render json: current_nsm_claim, status: :created
    rescue ActiveRecord::RecordInvalid => e
      report_error(e)
      render json: { errors: e.message }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      report_error(e)
      head :not_found
    end

  private

    def allowed_params
      params.permit(:ufn, :date_received, :firm_name,
                    :office_code, :stage_code, :client_last_name,
                    :work_completed_date, :court_name, :court_attendances,
                    :no_of_defendants)
    end

    def current_nsm_claim
      @current_nsm_claim ||= NsmClaim.find(params[:id])
    end
  end
end
