module Submissions
  class MetadataUpdateService
    class << self
      def call(submission, params)
        EventAdditionService.call(submission, params)
        submission.update!(params.permit(:application_risk))
      end
    end
  end
end
