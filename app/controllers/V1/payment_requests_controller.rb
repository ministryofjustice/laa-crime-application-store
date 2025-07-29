module V1
  class PaymentRequestsController < ApplicationController
    def update
      ::PaymentRequests::UpdateService.call(current_payment_request, params)
      render json: current_payment_request, status: :created
    rescue ActiveRecord::RecordInvalid => e
      handle_error(e)
      render json: { errors: e.message }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      handle_error(e)
      head :not_found
    end

    def link
      ::PaymentRequests::LinkService.call(current_payment_request, params)
      render json: current_payment_request, status: :created
    rescue ActiveRecord::RecordInvalid, PaymentLinkError => e
      handle_error(e)
      render json: { errors: e.message }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound => e
      handle_error(e)
      head :not_found
    end

  private

    def current_payment_request
      @current_payment_request ||= PaymentRequest.find(params[:id])
    end

    def authorization_object
      current_payment_request if action_name == "link"
    end
  end
end
