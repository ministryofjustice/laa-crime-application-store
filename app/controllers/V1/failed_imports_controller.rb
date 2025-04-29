module V1
  class FailedImportsController < ApplicationController
    def create
      raise AlreadyExistsError if FailedImport.find_by(id: params[:id])

      FailedImport.create!(id: params[:id], provider_id: params[:provider_id])
      head :created
    rescue AlreadyExistsError
      head :conflict
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end
  end
end
