module V1
  class SubscribersController < ApplicationController
    def create
      subscriber = Subscriber.new(params.permit(:webhook_url, :subscriber_type))
      if subscriber.save
        head :created
      elsif Subscriber.find_by(params.permit(:webhook_url, :subscriber_type))
        head :no_content
      else
        head :unprocessable_entity
      end
    end

    def destroy
      Subscriber.find_by(params.permit(:webhook_url, :subscriber_type)).destroy!
      head :no_content
    rescue ActiveRecord::StatementInvalid, NoMethodError
      head :not_found
    end
  end
end
