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
      expect(mail.to).to eq([claim.submitter.email])
    end

    context "when there are alternative contact emails" do
      before { claim.solicitor.update(contact_email: "alternative@example.com") }

      it "uses the alternative email" do
        expect(mail.to).to eq(["alternative@example.com"])
      end
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
          LAA_case_reference: "LAA-n4AohV",
          UFN: "120423/001",
          main_defendant_name: an_instance_of(String),
          defendant_reference: "MAAT ID number: 1234567",
          claim_total: "£20.45",
          date: Time.zone.now.to_fs(:stamp),
        )
      end
    end

    context "when defendant has cntp id" do
      let(:claim) { create(:claim, :firm_details, :case_type_breach, :breach_defendant, :letters_calls) }

      it "sets personalisation from args" do
        expect(
          mail.govuk_notify_personalisation,
        ).to include(
          LAA_case_reference: "LAA-n4AohV",
          UFN: "120423/002",
          main_defendant_name: an_instance_of(String),
          defendant_reference: /\AClient's CNTP number: CNTP\d+\z/,
          claim_total: "£20.45",
          date: Time.zone.now.to_fs(:stamp),
        )
      end
    end
  end

  it_behaves_like "notification client error handler" do
    let(:submission) { claim }
  end
end
