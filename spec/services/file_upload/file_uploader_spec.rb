require "rails_helper"

RSpec.describe FileUpload::FileUploader do
  let(:s3_object) { instance_double(Aws::S3::Object, delete: nil, exists?: true) }

  describe "#destroy" do
    it "deletes the file" do
      allow(S3_BUCKET).to receive(:object).with("aaaa-bbbb-1234").and_return(s3_object)
      expect(s3_object).to receive(:delete)
      described_class.new.destroy("aaaa-bbbb-1234")
    end

    it "does not raise an error if the file does not exist" do
      allow(S3_BUCKET).to receive(:object).with("aaaa-bbbb-1234").and_return(s3_object)
      expect(s3_object).to receive(:exists?)
      described_class.new.exists?("aaaa-bbbb-1234")
    end
  end
end
