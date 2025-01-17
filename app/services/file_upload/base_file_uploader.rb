module FileUpload
  class BaseFileUploader
    def destroy(file_path)
      perform_destroy(file_path)
    end

  protected

    def perform_destroy(_file_path)
      raise 'Implement perform_destroy in sub class'
    end
  end
end
