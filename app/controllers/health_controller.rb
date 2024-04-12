class HealthController < ApplicationController
  skip_before_action :authenticate!, only: :show

  def show
    render json: { healthy: :yes }, status: :ok
  end
end
