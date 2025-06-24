# https://dsdmoj.atlassian.net/browse/CRM457-2627

# accepts `start date` and `batch size` params
# be rake CRM457_2627:send_back_expired['2025-5-16', 10]

namespace :CRM457_2627 do
  desc "send_back_back expired"
  task :send_back_expired, [:start_date, :batch_size] => :environment do |_task, args|
    args.with_defaults(start_date: 1.day.ago.beginning_of_day, batch_size: 50)
    batch_size = args.batch_size
    start_date = Date.parse(args.start_date).beginning_of_day
    expired = expired_send_backs(start_date, batch_size)
    if expired.any?
      expired.find_each { send_back(_1) }
    else
      puts "No expired send_backs found"
    end
  end

  def expired_send_backs(start_date, batch_size)
    Submission.joins("LEFT JOIN application_version latest_version ON latest_version.application_id = application.id AND
      latest_version.version = (SELECT MAX(version)
      FROM application_version all_versions
      WHERE all_versions.application_id = application.id)")
      .where(state: :expired)
      .where("(latest_version.application->>'updated_at')::timestamp BETWEEN ? AND ? ", start_date, now.beginning_of_day)
      .limit(batch_size)
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
      Rails.logger.info("submission_id: #{submission.id} expired state changed to send_back")
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
end
