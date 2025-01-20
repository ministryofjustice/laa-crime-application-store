module FileUpload
  class FileUploader
    def destroy(file_path)
      remove_request = S3_BUCKET.object file_path
      remove_request.delete
    end
  end
end
