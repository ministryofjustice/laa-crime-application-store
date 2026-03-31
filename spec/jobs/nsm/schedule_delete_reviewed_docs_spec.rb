require "rails_helper"

RSpec.describe Nsm::ScheduleDeleteReviewedDocs, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new.perform }

  let!(:claim) { create(:submission, application_type:, state:, last_updated_at:) }

  describe "#perform" do
    context "when cron adds job to queue" do
      let(:application_type) { "crm7" }
      let(:state) { "granted" }
      let(:last_updated_at) { 6.months.ago }

      it "adds a job to the queue" do
        expect { described_class.new.perform }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end
    end

    context "when claims" do
      let(:application_type) { "crm7" }
      let(:state) { "granted" }
      let(:last_updated_at) { 6.months.ago }

      it "expect Nsm::DeleteReviewedClaimDocs to be queued" do
        expect(Nsm::DeleteReviewedClaimDocs).to receive(:perform_later).with(claim.id)
        described_class.new.perform
      end

      it "adds a job to the queue" do
        expect { described_class.new.perform }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end
    end

    context "when no claims" do
      let(:application_type) { "crm4" }
      let(:state) { "granted" }
      let(:last_updated_at) { 6.months.ago }

      it "does not add a job to the queue" do
        expect { described_class.new.perform }.not_to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size)
      end
    end
  end

  describe "#filterd_claims" do
    context "when PA" do
      let(:application_type) { "crm4" }

      context "when last_updated_at" do
        describe "greater than 6 months ago" do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is not included" do
            expect(described_class.new.filtered_claims).not_to include(claim)
          end
        end
      end
    end

    context "when NSM" do
      let(:application_type) { "crm7" }

      context "when last_updated_at" do
        describe "greater than 6 months ago" do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is included" do
            expect(described_class.new.filtered_claims).to include(claim)
          end
        end

        describe "less than 6 months ago" do
          let(:state) { "part_grant" }
          let(:last_updated_at) { 1.day.ago }

          it "is excluded" do
            expect(described_class.new.filtered_claims).not_to include(claim)
          end
        end

        describe 'latest_version.application["gdpr_documents_deleted"] absent' do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is excluded" do
            expect(described_class.new.filtered_claims).to include(claim)
          end
        end

        describe 'latest_version.application["gdpr_documents_deleted"] false' do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is excluded" do
            claim.latest_version.update!(application: { gdpr_documents_deleted: false })
            expect(described_class.new.filtered_claims).to include(claim)
          end
        end

        describe 'latest_version.application["gdpr_documents_deleted"] true' do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is excluded" do
            claim.latest_version.update!(application: { gdpr_documents_deleted: true })
            expect(described_class.new.filtered_claims).not_to include(claim)
          end
        end
      end
    end
  end
end
