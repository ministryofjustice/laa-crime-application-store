# https://dsdmoj.atlassian.net/browse/CRM457-2627

namespace :CRM457_2627 do
  desc "send_back_back expired"
  task send_back_expired: :environment do
    expired_send_backs.find_each { send_back(_1) }
  end

  def expired_send_backs
    Submission.joins("LEFT JOIN application_version latest_version ON latest_version.application_id = application.id AND
                                        latest_version.version = (SELECT MAX(version)
                                                                  FROM application_version all_versions
                                                                  WHERE all_versions.application_id = application.id)")
              .where(state: :expired)
      .where("(latest_version.application->>'updated_at')::timestamp BETWEEN ? AND ? ", start_date, now.beginning_of_day)
   end

  def send_back(submission)
    submission.with_lock do
      submission.state = "send_back"
      submission.current_version += 1
      submission.last_updated_at = now
      submission.caseworker_history_events << build_event(now, submission.current_version)
      submission.save!

      latest_version = submission.latest_version
      submission.ordered_submission_versions.create!(
        json_schema_version: latest_version.json_schema_version,
        application: latest_version.application.merge("updated_at" => now,
          "status" => "send_back",
          "resubmission_deadline" => resubmission_deadline),
        version: submission.current_version,
      )
      puts "submission_id: #{submission.id} expired state changed to send_back"
    end
  end

  def resubmission_deadline
    @resubmission_deadline ||= LaaCrimeFormsCommon::WorkingDayService.call(Rails.application.config.x.rfi.working_day_window)
  end

  def now
    @now ||= Time.zone.now
  end

  def build_event(now, current_version)
    {
      submission_version: current_version,
      id: SecureRandom.uuid,
      created_at: now,
      details: {},
      updated_at: now,
      event_type: "send_back",
      public: false,
      does_not_constitute_update: false,
    }
  end

  def start_date
    Date.new(2025, 5, 16).beginning_of_day
  end
end
