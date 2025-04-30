require "rails_helper"

RSpec.describe Nsm::ClearImportErrorDetails do
  job { described_class.new }

  before do
    failed_import&.save
  end

  describe "#perform" do
    let(:failed_import) { nil }

    before do
      failed_import
    end

    context "when the failed is older than a week old" do
      let(:failed_import) { create(:failed_import, created_at: 1.week.ago) }

      it "updates the db record when a week" do
        expect(job.filtered_records).not_to eq([])
        job.perform

        failed_import.reload
        expect(failed_import.details).to be_nil
      end
    end

    context "when the failed import is not older than a week" do
      let(:failed_import) { create(:failed_import, created_at: Time.zone.today) }

      it "does not update the record when not more than a week old" do
        expect(job.filtered_records).to eq([])

        job.perform

        failed_import.reload
        expect(failed_import.details).not_to be_nil
      end
    end
  end
end
