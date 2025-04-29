module V1
  class FailedImportsController < ApplicationController
    def create
      raise AlreadyExistsError if FailedImport.find_by(id: params[:id])

      failed_import = FailedImport.create!(id: params[:id], provider_id: params[:provider_id])
      render json: failed_import, status: :created
    rescue AlreadyExistsError
      head :conflict
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end
  end
end
