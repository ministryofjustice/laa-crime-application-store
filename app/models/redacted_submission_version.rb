class RedactedSubmissionVersion < ApplicationRecord
  belongs_to :submission_version
  belongs_to :submission

  self.table_name = "redacted_application_versions"

  # attr_readonly :id, :status, :submitted_application
end
