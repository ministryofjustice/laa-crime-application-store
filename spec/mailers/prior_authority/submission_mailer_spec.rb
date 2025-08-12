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
      expect(mail.to).to eq(["james@email.com"])
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
        laa_case_reference: "LAA-n4AohV",
        ufn: "120423/001",
        defendant_name: an_instance_of(String),
        application_total: "£155.00",
        date: Time.zone.now.to_fs(:stamp),
      )
    end
  end

  it_behaves_like "notification client error handler" do
    let(:submission) { application }
  end
end
