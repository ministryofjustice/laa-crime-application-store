module V1
  class PayableClaimsController < ApplicationController
    def show
      render json: payable_claim_resource, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      report_error(e)
      head :not_found
    end

  private

    def payable_claim_resource
      payable_claim ||= PayableClaim.find(params[:id])

      @payable_claim_resource ||= PayableClaimResource.new(
        payable_claim, params: { include_claim: false }
      ).serialize
    end
  end
end
