require "rails_helper"

RSpec.describe FileUpload::FileUploader do
  let(:s3_object) { instance_double(Aws::S3::Object, delete: nil) }

  describe "#destroy" do
    it "deletes the file" do
      allow(S3_BUCKET).to receive(:object).with("aaaa-bbbb-1234").and_return(s3_object)
      expect(s3_object).to receive(:delete)
      described_class.new.destroy("aaaa-bbbb-1234")
    end
  end
end
