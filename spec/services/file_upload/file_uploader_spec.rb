require "rails_helper"

RSpec.describe FileUpload::FileUploader do
  describe "#destroy" do
    it "deletes the file" do
      allow(S3_BUCKET).to receive(:object).with("aaaa-bbbb-1234").and_return(double(delete: true))
      expect(described_class.new.destroy("aaaa-bbbb-1234")).to be_truthy
    end
  end
end
