class Submission < ApplicationRecord
  self.table_name = "application"
  has_many :submission_versions, dependent: :destroy, foreign_key: "application_id"

  validates :application_state, presence: true
  validates :application_type, presence: true
  validates :application_risk, presence: true

  def latest_version
    # Optimisation: When pulling lists of submissions, this allows a single DB lookup using #includes,
    # instead of going back to the database for every submission
    submission_versions.max_by(&:version)
  end

  def as_json(*)
    super(only: %i[application_state application_risk application_type updated_at created_at]).merge(
      version: current_version,
      json_schema_version: latest_version.json_schema_version,
    ).merge(application: latest_version.application, events:, application_id: id)
  end
end
