module FileUpload
  class AwsFileUploader < BaseFileUploader
  protected

    def perform_destroy(file_path)
      remove_request = S3_BUCKET.object file_path
      remove_request.delete
    end
  end
end
