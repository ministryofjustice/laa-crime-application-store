class Submission < ApplicationRecord
  self.table_name = "application"
  has_many :ordered_submission_versions, -> { order(version: :desc) },
           dependent: :destroy,
           foreign_key: "application_id",
           class_name: "SubmissionVersion"

  validates :state, presence: true
  validates :application_type, presence: true
  validates :application_risk, presence: true

  def latest_version
    ordered_submission_versions.first
  end

  def as_json(*)
    super(only: %i[application_risk application_type updated_at created_at]).merge(
      application_state: state,
      version: current_version,
      json_schema_version: latest_version.json_schema_version,
    ).merge(application: latest_version.application, events:, application_id: id)
  end
end
