class SubmissionVersion < ApplicationRecord
  belongs_to :submission

  validates :json_schema_version, presence: true
  validates :data, presence: true
end
