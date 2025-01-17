require "rails_helper"

RSpec.describe Nsm::DeleteReviewedClaimDocs do
  describe "#perform" do
    let(:claim) { create(:submission) }
    let(:file_uploader) { instance_double(FileUpload::FileUploader, destroy: true) }
    let(:supporting_evidences) do
      [
        { id: 123, file_path: "123-a.pdf" },
        { id: 456, file_path: "456-b.pdf" },
        { id: 789, file_path: "789-c.pdf" },
      ]
    end

    before do
      allow(FileUpload::FileUploader).to receive(:new).and_return(file_uploader)
      claim.latest_version.update!(application: { supporting_evidences: })
    end

    describe "#perform" do
      it "calls destroy with filepath from supporting evidence" do
        expect(file_uploader).to receive(:destroy).with("123-a.pdf").once
        expect(file_uploader).to receive(:destroy).with("456-b.pdf").once
        expect(file_uploader).to receive(:destroy).with("789-c.pdf").once
        described_class.new.perform(claim)
      end

      it "creates a new version" do
        expect{ described_class.new.perform(claim) }.to change { claim.ordered_submission_versions.count }.by(1)
      end

      it "raise an error if file deletion fails" do
        allow(file_uploader).to receive(:destroy).with("123-a.pdf").and_return(false)
        expect { described_class.new.perform(claim) }.to raise_error(Nsm::DeleteReviewedClaimDocs::GDPRDeletionError)
      end

      it "adds an event to the claim" do
        described_class.new.perform(claim)
        expect(claim.reload.caseworker_history_events.last["event_type"]).to eq("gdpr_supporting_evidence")
      end

      it "adds a uploads_purged flag to the latest_version" do
        described_class.new.perform(claim)
        expect(claim.reload.latest_version.application["uploads_purged"]).to be(true)
      end
    end
  end
end
