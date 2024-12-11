class Submission < ApplicationRecord
  self.table_name = "application"
  has_many :ordered_submission_versions, -> { order(version: :desc) },
           dependent: :destroy,
           foreign_key: "application_id",
           class_name: "SubmissionVersion"

  attribute :events, :jsonb, default: -> { [] }

  validates :state, presence: true
  validates :application_type, presence: true

  def latest_version(include_pending: true)
    ordered_submission_versions.then { include_pending ? _1 : _1.where(pending: false) }.first
  end

  def as_json(args = {})
    version = latest_version(include_pending: args[:client_role] == :caseworker)
    super(only: %i[application_risk application_type updated_at created_at last_updated_at assigned_user_id]).merge(
      application_state: state,
      version: current_version,
      json_schema_version: version.json_schema_version,
    ).merge(application: version.application, events:, application_id: id)
  end
end
