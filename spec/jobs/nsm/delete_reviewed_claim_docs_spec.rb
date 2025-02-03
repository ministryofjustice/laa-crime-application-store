require "rails_helper"

RSpec.describe Nsm::DeleteReviewedClaimDocs do
  describe "#perform" do
    let(:claim) { create(:submission) }
    let(:file_uploader) { instance_double(FileUpload::FileUploader, destroy: true, exists?: true) }
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

    describe "when redacting data" do
      it "only processes expected records" do
        initial_data = [
          { file_name: "path.png" },
          { file_name: "other_path.png" },
        ]
        changed_data = [
          { file_name: "<Redacted for GDPR compliance>" },
          { file_name: "other_path.png" },
        ]
        expect(described_class.new.redact_file_names(initial_data, "path.png")).to eq(changed_data)
      end

      it "correctly recurses and adjusts only the expected records" do
        initial_data = [
          { parent: {
            another_parent: {
              more_nesting: [
                { file_name: "path.png" },
              ],
            },
            file_name: "path.png",
          } },
          { file_name: "path.png" },
          { file_name: "other_path.png" },
        ]
        changed_data = [
          { parent: {
            another_parent: {
              more_nesting: [
                { file_name: "<Redacted for GDPR compliance>" },
              ],
            },
            file_name: "<Redacted for GDPR compliance>",
          } },
          { file_name: "<Redacted for GDPR compliance>" },
          { file_name: "other_path.png" },
        ]

        expect(described_class.new.redact_file_names(initial_data, "path.png")).to eq(changed_data)
      end
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
          allow(file_uploader).to receive(:exists?).with("a.pdf").and_return(false)
          expect(Rails.logger).to receive(:error).with("Delete failed for document: a.pdf submission: #{claim.id}")
          described_class.new.perform(claim.id)
        end

        it "adds an event to the claim" do
          described_class.new.perform(claim.id)
          expect(claim.reload.caseworker_history_events.last["event_type"]).to eq("gdpr_documents_deleted")
        end

        it "adds a uploads_purged flag to the latest_version" do
          described_class.new.perform(claim.id)
          expect(claim.reload.latest_version.application["gdpr_documents_deleted"]).to be(true)
        end

        it "removes the filenames from the history for supporting evidence" do
          versions = SubmissionVersion.where(application_id: claim.id)
          expect(versions.pluck(Arel.sql("jsonb_array_elements(application->'supporting_evidences')->>'file_path'"))).to eq(["a.pdf", "b.pdf", "c.pdf"])

          described_class.new.perform(claim.id)

          # We expect 6 iterations here as the change creates a new version, 3 filenames across 2 versions = 6 total filenames
          expect(versions.pluck(Arel.sql("jsonb_array_elements(application->'supporting_evidences')->>'file_path'"))).to eq(["<Redacted for GDPR compliance>"] * 6)
        end

        it "removes the filenames from the history for further information" do
          versions = SubmissionVersion.where(application_id: claim.id)
          file_paths = versions.pluck(Arel.sql("jsonb_array_elements(application->'further_information')->>'documents'")).flatten.compact.map { |docs| JSON.parse(docs).map { |doc| doc["file_path"] } }.flatten

          expect(file_paths).to eq(["x.pdf", "y.pdf", "z.pdf"])

          described_class.new.perform(claim.id)

          file_paths = versions.pluck(Arel.sql("jsonb_array_elements(application->'further_information')->>'documents'")).flatten.compact.map { |docs| JSON.parse(docs).map { |doc| doc["file_path"] } }.flatten

          # We expect 6 iterations here as the change creates a new version, 3 filenames across 2 versions = 6 total filenames
          expect(file_paths).to eq(["<Redacted for GDPR compliance>"] * 6)
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
