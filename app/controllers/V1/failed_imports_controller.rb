module V1
  class FailedImportsController < ApplicationController
    def create
      failed_import = ::FailedImports::CreationService.call(params)
      render json: failed_import, status: :created
    rescue ::FailedImports::CreationService::AlreadyExistsError
      head :conflict
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end
  end
end
