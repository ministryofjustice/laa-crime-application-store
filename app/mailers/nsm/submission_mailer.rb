# frozen_string_literal: true

module Nsm
  class SubmissionMailer < GovukNotifyRails::Mailer
    def notify(submission)
      @data = submission.latest_version.application
      @claim = V1::Nsm::Claim.new(submission)
      set_template("0403454c-47a5-4540-804c-cb614e77dc22")
      set_personalisation(
        LAA_case_reference: case_reference,
        UFN: unique_file_number,
        main_defendant_name: defendant_name,
        defendant_reference: defendant_reference_string,
        claim_total: claim_total,
        date: submission_date,
      )
      mail(to: email_recipient)
    end

  private

    def email_recipient
      @data.dig("solicitor", "contact_email").presence
    end

    def case_reference
      @data["laa_reference"]
    end

    def unique_file_number
      @data["ufn"]
    end

    def defendant_name
      [
        @claim.main_defendant["first_name"],
        @claim.main_defendant["last_name"],
      ].join(" ")
    end

    def maat_id
      @claim.main_defendant["maat"]
    end

    def cntp_order
      @data["cntp_order"]
    end

    # Markdown conditionals do not allow to format the string nicely so formatting here.
    def defendant_reference_string
      if maat_id.nil?
        "Client's CNTP number: #{cntp_order}"
      else
        "MAAT ID number: #{maat_id}"
      end
    end

    def claim_total
      NumberTo.pounds(@claim.totals[:totals][:claimed_total_inc_vat])
    end

    def submission_date
      Time.zone.now.to_fs(:stamp)
    end
  end
end
