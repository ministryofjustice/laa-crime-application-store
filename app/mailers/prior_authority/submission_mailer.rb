# frozen_string_literal: true

module PriorAuthority
  class SubmissionMailer < NotifyMailer
    def notify(submission)
      @data = submission.latest_version.application
      @application = V1::PriorAuthority::ApplicationPresenter.new(submission)
      set_template("d07d03fd-65d0-45e4-8d49-d4ee41efad35")
      set_personalisation(
        laa_case_reference: case_reference,
        ufn: unique_file_number,
        defendant_name: defendant_name,
        application_total: application_total,
        date: submission_date,
      )
      mail(to: email_recipient)
    end

  private

    def defendant_name
      @application.defendant_full_name
    end

    def email_recipient
      @data.dig("solicitor", "contact_email").presence
    end

    def case_reference
      @data["laa_reference"]
    end

    def unique_file_number
      @data["ufn"]
    end

    def application_total
      LaaCrimeFormsCommon::NumberTo.pounds(@application.primary_quote.total_cost)
    end

    def submission_date
      Time.zone.now.to_fs(:stamp)
    end
  end
end
