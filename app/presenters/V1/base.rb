module V1
  class Base
    def initialize(submission)
      @submission = submission
      @application = submission.latest_version.application
    end
  end
end
