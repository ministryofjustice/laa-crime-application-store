require "rails_helper"

RSpec.describe "Create failed import" do
  context "when authenticated with bearer token" do
    let(:provider_id) { SecureRandom.uuid }

    before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :provider) }

    it "saves what I send to failed_imports" do
      post "/v1/failed_imports", params: {
        provider_id: provider_id,
      }
      expect(response).to have_http_status :created
      expect(FailedImport.first.provider_id).to eq(provider_id)
    end

    it "fails when params are incorrect type" do
      post "/v1/failed_imports", params: {
        provider_id: "garbage",
      }

      expect(response).to have_http_status :unprocessable_entity
    end
  end
end
