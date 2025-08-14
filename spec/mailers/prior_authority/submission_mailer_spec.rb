# frozen_string_literal: true

require "rails_helper"

RSpec.describe PriorAuthority::SubmissionMailer, type: :mailer do
  let(:feedback_template) { "d07d03fd-65d0-45e4-8d49-d4ee41efad35" }
  let(:application) do
    create(
      :submission,
      :with_pa_version,
    )
  end

  describe "#notify" do
    subject(:mail) { described_class.notify(application) }

    it "is a govuk_notify delivery" do
      expect(mail.delivery_method).to be_a(GovukNotifyRails::Delivery)
    end

    it "sets the recipient to solicitors contact email" do
      expect(mail.to).to eq(["john@doe.com"])
    end

    it "sets the template" do
      expect(
        mail.govuk_notify_template,
      ).to eq feedback_template
    end

    it "sets personalisation from args" do
      expect(
        mail.govuk_notify_personalisation,
      ).to include(
        laa_case_reference: "LAA-123456",
        ufn: "010124/001",
        defendant_name: "Joe Bloggs",
        application_total: "£175.00",
        date: Time.zone.now.to_fs(:stamp),
      )
    end
  end
end
