require "rails_helper"

RSpec.describe Nsm::DeleteReviewedClaimDocs do
  describe "#perform" do
    let(:claim) { create(:submission) }
    let(:file_uploader) { instance_double(FileUpload::FileUploader, destroy: true, exists?: true) }
    let(:supporting_evidences) do
      [
        { id: 123, file_path: "aaaa", file_name: "a.pdf" },
        { id: 456, file_path: "bbbb", file_name: "b.pdf" },
        { id: 789, file_path: "cccc", file_name: "c.pdf" },
      ]
    end

    let(:further_information) do
      [
        { documents:
          [
            { file_path: "xxxx", file_name: "x.pdf" },
            { file_path: "yyyy", file_name: "y.pdf" },
          ],
          information_supplied: "test" },
        { documents:
          [
            { file_path: "zzzz", file_name: "z.pdf" },
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
          { file_name: "path.png", file_path: "1234" },
          { file_name: "other_path.png", file_path: "4321" },
        ]
        changed_data = [
          { file_name: "<Redacted for GDPR compliance>", file_path: "1234" },
          { file_name: "other_path.png", file_path: "4321" },
        ]
        expect(described_class.new.redact_file_names(initial_data, "path.png")).to eq(changed_data)
      end

      it "correctly recurses and adjusts only the expected records" do
        initial_data = [
          { parent: {
            another_parent: {
              more_nesting: [
                { file_name: "path.png", file_path: "1234" },
              ],
            },
            file_name: "path.png",
            file_path: "1234",
          } },
          { file_name: "path.png", file_path: "1234" },
          { file_name: "other_path.png", file_path: "4321" },
        ]
        changed_data = [
          { parent: {
            another_parent: {
              more_nesting: [
                { file_name: "<Redacted for GDPR compliance>", file_path: "1234" },
              ],
            },
            file_name: "<Redacted for GDPR compliance>",
            file_path: "1234",
          } },
          { file_name: "<Redacted for GDPR compliance>", file_path: "1234" },
          { file_name: "other_path.png", file_path: "4321" },
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
          expect(file_uploader).to receive(:destroy).with("aaaa").once
          expect(file_uploader).to receive(:destroy).with("bbbb").once
          expect(file_uploader).to receive(:destroy).with("cccc").once
          expect(file_uploader).to receive(:destroy).with("xxxx").once
          expect(file_uploader).to receive(:destroy).with("yyyy").once
          expect(file_uploader).to receive(:destroy).with("zzzz").once
          described_class.new.perform(claim.id)
        end

        it "creates a new version" do
          expect { described_class.new.perform(claim.id) }.to change { claim.ordered_submission_versions.count }.by(1)
        end

        it "raise an error if file deletion fails" do
          allow(file_uploader).to receive(:exists?).with("aaaa").and_return(false)
          expect(Rails.logger).to receive(:error).with("Delete failed for document: aaaa submission: #{claim.id}")
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
          expect(versions.pluck(Arel.sql("jsonb_array_elements(application->'supporting_evidences')->>'file_name'"))).to eq(["a.pdf", "b.pdf", "c.pdf"])

          described_class.new.perform(claim.id)

          # We expect 6 iterations here as the change creates a new version, 3 filenames across 2 versions = 6 total filenames
          expect(versions.pluck(Arel.sql("jsonb_array_elements(application->'supporting_evidences')->>'file_name'"))).to eq(["<Redacted for GDPR compliance>"] * 6)
        end

        it "removes the filenames from the history for further information" do
          versions = SubmissionVersion.where(application_id: claim.id)
          file_names = versions.pluck(Arel.sql("jsonb_array_elements(application->'further_information')->>'documents'")).flatten.compact.map { |docs| JSON.parse(docs).map { |doc| doc["file_name"] } }.flatten

          expect(file_names).to eq(["x.pdf", "y.pdf", "z.pdf"])

          described_class.new.perform(claim.id)

          file_names = versions.pluck(Arel.sql("jsonb_array_elements(application->'further_information')->>'documents'")).flatten.compact.map { |docs| JSON.parse(docs).map { |doc| doc["file_name"] } }.flatten

          # We expect 6 iterations here as the change creates a new version, 3 filenames across 2 versions = 6 total filenames
          expect(file_names).to eq(["<Redacted for GDPR compliance>"] * 6)
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
          expect(file_uploader).to receive(:destroy).with("aaaa").once
          expect(file_uploader).to receive(:destroy).with("bbbb").once
          expect(file_uploader).to receive(:destroy).with("cccc").once
          expect(file_uploader).not_to receive(:destroy).with("xxxx")
          expect(file_uploader).not_to receive(:destroy).with("yyyy")
          expect(file_uploader).not_to receive(:destroy).with("zzzz")
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
