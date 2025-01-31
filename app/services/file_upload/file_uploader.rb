module FileUpload
  class FileUploader
    def destroy(file_path)
      remove_request = S3_BUCKET.object file_path
      remove_request.delete
    end

    def exists?(file_path)
      S3_BUCKET.object(file_path).exists?
    end
  end
end
