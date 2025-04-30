module V1
  class FailedImportsController < ApplicationController
    def create
      @current_import_error = FailedImport.create!(provider_id: params[:provider_id], details: params[:details])
      render json: current_import_error, status: :created
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def show
      render json: current_import_error
    end

    private

    def current_import_error
      @current_import_error ||= Failed_Import.find(params[:id])
    end
  end
end
