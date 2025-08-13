# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nsm::SubmissionMailer, type: :mailer do
  let(:feedback_template) { "0403454c-47a5-4540-804c-cb614e77dc22" }
  let(:claim) { create(:submission, :with_nsm_version) }

  describe "#notify" do
    subject(:mail) { described_class.notify(claim) }

    it "is a govuk_notify delivery" do
      expect(mail.delivery_method).to be_a(GovukNotifyRails::Delivery)
    end

    it "sets the recipient from claim provider" do
      expect(mail.to).to eq(["john@doe.com"])
    end

    it "sets the template" do
      expect(
        mail.govuk_notify_template,
      ).to eq feedback_template
    end

    context "when defendant has maat id number" do
      it "sets personalisation from args" do
        expect(
          mail.govuk_notify_personalisation,
        ).to include(
          LAA_case_reference: "LAA-123456",
          UFN: "010124/001",
          main_defendant_name: "Joe Bloggs",
          defendant_reference: "MAAT ID number: 1234567",
          claim_total: "£4,268.75",
          date: Time.zone.now.to_fs(:stamp),
        )
      end
    end

    context "when defendant has cntp id" do
      let(:claim) { create(:submission, build_scope: [:with_nsm_breach_application]) }

      it "sets personalisation from args" do
        expect(
          mail.govuk_notify_personalisation,
        ).to include(
          LAA_case_reference: "LAA-123456",
          UFN: "010124/001",
          main_defendant_name: "Joe Bloggs",
          defendant_reference: "Client's CNTP number: CNTP100",
          claim_total: "£4,268.75",
          date: Time.zone.now.to_fs(:stamp),
        )
      end
    end
  end
end
