require "rails_helper"

RSpec.describe Nsm::DeleteReviewedClaimDocs do
  describe "#perform" do
    let(:claim) { create(:submission) }
    let(:file_uploader) { instance_double(FileUpload::FileUploader, destroy: true) }
    let(:supporting_evidences) do
      [
        { id: 123, file_path: "a.pdf" },
        { id: 456, file_path: "b.pdf" },
        { id: 789, file_path: "c.pdf" },
      ]
    end

    let(:further_information) do
      [
        { documents:
          [
            { file_path: "x.pdf" },
            { file_path: "y.pdf" },
          ],
          information_supplied: "test" },
        { documents:
          [
            { file_path: "z.pdf" },
          ],
          information_supplied: "test" },

        { documents:
          [],
          information_supplied: "test" },
      ]
    end

    context "when supporting evidences and further informations are present" do
      before do
        allow(FileUpload::FileUploader).to receive(:new).and_return(file_uploader)
        claim.latest_version.update!(application: { supporting_evidences:, further_information: })
      end

      describe "#perform" do
        it "calls destroy with filepath from supporting evidence and further informations" do
          expect(file_uploader).to receive(:destroy).with("a.pdf").once
          expect(file_uploader).to receive(:destroy).with("b.pdf").once
          expect(file_uploader).to receive(:destroy).with("c.pdf").once
          expect(file_uploader).to receive(:destroy).with("x.pdf").once
          expect(file_uploader).to receive(:destroy).with("y.pdf").once
          expect(file_uploader).to receive(:destroy).with("z.pdf").once
          described_class.new.perform(claim.id)
        end

        it "creates a new version" do
          expect { described_class.new.perform(claim.id) }.to change { claim.ordered_submission_versions.count }.by(1)
        end

        it "raise an error if file deletion fails" do
          allow(file_uploader).to receive(:destroy).with("a.pdf").and_return(false)
          expect { described_class.new.perform(claim.id) }.to raise_error(Nsm::DeleteReviewedClaimDocs::GDPRDeletionError)
        end

        it "adds an event to the claim" do
          described_class.new.perform(claim.id)
          expect(claim.reload.caseworker_history_events.last["event_type"]).to eq("gdpr_documents_deleted")
        end

        it "adds a uploads_purged flag to the latest_version" do
          described_class.new.perform(claim.id)
          expect(claim.reload.latest_version.application["gdpr_documents_deleted"]).to be(true)
        end
      end
    end

    context "when supporting evidences and further informations are not present" do
      before do
        allow(FileUpload::FileUploader).to receive(:new).and_return(file_uploader)
        claim.latest_version.update!(application: { supporting_evidences: })
      end

      describe "#perform" do
        it "calls destroy with filepath from supporting evidence and further informations" do
          expect(file_uploader).to receive(:destroy).with("a.pdf").once
          expect(file_uploader).to receive(:destroy).with("b.pdf").once
          expect(file_uploader).to receive(:destroy).with("c.pdf").once
          expect(file_uploader).not_to receive(:destroy).with("x.pdf")
          expect(file_uploader).not_to receive(:destroy).with("y.pdf")
          expect(file_uploader).not_to receive(:destroy).with("z.pdf")
          described_class.new.perform(claim.id)
        end
      end
    end

    context "when supporting evidences and further informations contain no docs" do
      let(:further_information) do
        [
          { documents:
            [],
            information_supplied: "test" },
        ]
      end

      before do
        allow(FileUpload::FileUploader).to receive(:new).and_return(file_uploader)
        claim.latest_version.update!(application: { supporting_evidences: [], further_information: })
      end

      describe "#perform" do
        it "calls destroy with filepath from supporting evidence and further informations" do
          expect(described_class.new.perform(claim.id)).to be_nil
        end
      end
    end
  end
end
