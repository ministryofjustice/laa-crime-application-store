class HealthController < ApplicationController
  skip_before_action :authenticate!, only: :show
  skip_before_action :authorize!, only: :show

  def show
    render json: build_args, status: :ok
  end

private

  def build_args
    {
      app_branch: ENV.fetch("APP_BRANCH_NAME", nil),
      build_date: ENV.fetch("APP_BUILD_DATE", nil),
      build_tag: ENV.fetch("APP_BUILD_TAG", nil),
      commit_id: ENV.fetch("APP_GIT_COMMIT", nil),
    }
  end
end
