require "rails_helper"

RSpec.describe Nsm::ScheduleDeleteReviewedDocs do
  let!(:claim) { create(:submission, application_type:, state:, last_updated_at:) }

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

        describe 'latest_version.application["documents_purged"] absent' do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is excluded" do
            expect(described_class.new.filtered_claims).to include(claim)
          end
        end

        describe 'latest_version.application["documents_purged"] false' do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is excluded" do
            claim.latest_version.update!(application: { uploads_purged: false })
            expect(described_class.new.filtered_claims).to include(claim)
          end
        end

        describe 'latest_version.application["documents_purged"] true' do
          let(:state) { "granted" }
          let(:last_updated_at) { 6.months.ago }

          it "is excluded" do
            claim.latest_version.update!(application: { uploads_purged: true })

            expect(described_class.new.filtered_claims).not_to include(claim)
          end
        end
      end
    end
  end
end
