module V1
  class FailedImportsController < ApplicationController
    def create
      FailedImport.create!(provider_id: params[:provider_id])
      head :created
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end
  end
end
