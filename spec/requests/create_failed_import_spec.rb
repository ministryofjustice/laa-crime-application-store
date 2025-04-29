require "rails_helper"

RSpec.describe "Create failed import" do
  context "when authenticated with bearer token" do
    let(:id) { SecureRandom.uuid }
    let(:provider_id) { SecureRandom.uuid }
    let(:details) { "some error happened" }

    before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :provider) }

    it "saves what I send to failed_imports" do
      post "/v1/failed_import", params: {
        id: id,
        provider_id: provider_id,
      }
      expect(response).to have_http_status :created

      expect(FailedImport.first.id).to eq(id)
      expect(FailedImport.first.provider_id).to eq(provider_id)
    end
  end
end
