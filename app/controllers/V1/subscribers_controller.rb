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
      current_subscriber.destroy!
      head :no_content
    rescue ActiveRecord::StatementInvalid, NoMethodError
      head :not_found
    end

    def current_subscriber
      @current_subscriber = Subscriber.find_by(params.permit(:webhook_url, :subscriber_type))
    end

    def authorization_object
      current_subscriber if action_name == "destroy"
    end
  end
end
