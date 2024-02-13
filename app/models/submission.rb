class Submission < ApplicationRecord
  has_many :submission_versions, dependent: :destroy

  validates :application_id, presence: true
  validates :application_state, presence: true
  validates :application_type, presence: true
  validates :application_risk, presence: true

  def current_version_number
    # Optimisation: For lists, this allows a single DB lookup using #includes,
    # instead of going back to the database for every submission
    submission_versions.to_a.size
  end

  def current_version
    # Optimisation: For lists, this allows a single DB lookup using #includes,
    # instead of going back to the database for every submission
    submission_versions.max_by(&:created_at)
  end

  def as_json(*)
    super(only: %i[application_id application_state application_risk application_type updated_at created_at assigned_user_id]).merge(
      version: current_version_number,
      json_schema_version: current_version.json_schema_version,
    ).merge(application: current_version.data, events:)
  end
end
