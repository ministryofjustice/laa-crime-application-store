module V1
  class PaymentRequestsController < ApplicationController
    def create
      payment_request = PaymentRequest.create!(
        request_type: params[:request_type],
        submitter_id: params[:submitter_id],
      )
      render json: payment_request, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end

    def update
      ::PaymentRequests::UpdateService.call(current_payment_request, params)
      render json: current_payment_request, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.message }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

  private

    def current_payment_request
      @current_payment_request ||= PaymentRequest.find(params[:id])
    end
  end
end
