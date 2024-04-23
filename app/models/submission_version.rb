class SubmissionVersion < ApplicationRecord
  include Redactable

  self.table_name = "application_version"
  belongs_to :submission, foreign_key: "application_id"

  validates :json_schema_version, presence: true
  validates :application, presence: true
  validates :version, presence: true
end
