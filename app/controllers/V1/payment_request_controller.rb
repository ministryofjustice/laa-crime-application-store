module V1
  class PaymentRequestController < ApplicationController
    def update
      ::PaymentRequests::UpdateService.call(current_payment_request, params)
      render json: current_payment_request, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end

  private

    def current_payment_request
      @current_payment_request ||= PaymentRequest.find(params[:id])
    end
  end
end
