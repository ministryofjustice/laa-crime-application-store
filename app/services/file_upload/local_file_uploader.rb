module FileUpload
  class LocalFileUploader < BaseFileUploader
    def initialize
      super
      @file_path = Rails.root.join('tmp/uploaded/').to_s
      FileUtils.mkdir_p(@file_path) unless File.directory?(@file_path)
    end

  protected

    def perform_destroy(file_path)
      FileUtils.remove file_path
    end
  end
end
