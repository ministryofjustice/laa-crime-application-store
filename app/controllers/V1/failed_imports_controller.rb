module V1
  class FailedImportsController < ApplicationController
    def create
      raise AlreadyExistsError if FailedImport.find_by(id: params[:id])

      FailedImport.transaction do
        failed_import = FailedImport.create!(id: params[:id], provider_id: params[:provider_id])
        failed_import
      end

      render json: failed_import, status: :created
    rescue AlreadyExistsError
      head :conflict
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end
  end
end
