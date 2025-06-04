module V1
  class FailedImportsController < ApplicationController
    def show
      render json: current_import_error
    end

    def create
      @current_import_error = FailedImport.create!(provider_id: params[:provider_id],
                                                   details: params[:details],
                                                   error_type: params[:error_type])
      render json: current_import_error, status: :created
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

  private

    def current_import_error
      @current_import_error ||= FailedImport.find(params[:id])
    end
  end
end
