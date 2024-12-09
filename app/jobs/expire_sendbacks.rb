class ExpireSendbacks < ApplicationJob
  def perform
    Submission.joins("LEFT JOIN application_version latest_version ON latest_version.application_id = application.id AND
                                        latest_version.version = (SELECT MAX(version)
                                                                  FROM application_version all_versions
                                                                  WHERE all_versions.application_id = application.id)")
              .where(state: :sent_back)
              .where("(latest_version.application->>'resubmission_deadline')::timestamp < NOW()")
              .find_each { expire(_1) }
  end

private

  def expire(submission)
    now = Time.zone.now
    submission.with_lock do
      submission.state = "expired"
      submission.current_version += 1
      submission.last_updated_at = now
      submission.events << build_expiry_event(now, submission.current_version)
      submission.save!

      latest_version = submission.latest_version
      submission.ordered_submission_versions.create!(
        json_schema_version: latest_version.json_schema_version,
        application: latest_version.application.merge("updated_at" => now, "status" => "expired"),
        version: submission.current_version,
      )
    end
  end

  def build_expiry_event(now, current_version)
    {
      submission_version: current_version,
      id: SecureRandom.uuid,
      created_at: now,
      details: {},
      updated_at: now,
      event_type: "expiry",
      public: false,
      does_not_constitute_update: false,
    }
  end
end
