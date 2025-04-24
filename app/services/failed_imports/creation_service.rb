module FailedImports
  class CreationService
    AlreadyExistsError = Class.new(StandardError)
    class << self
      def call(params)
        raise AlreadyExistsError if FailedImport.find_by(id: params[:id])

        FailedImport.transaction do
          failed_import = FailedImport.create!(id: params[:id], provider_id: params[:provider_id])
          failed_import
        end
      end
    end
  end
end
