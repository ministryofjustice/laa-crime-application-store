require "rails_helper"

RSpec.describe "Show failed import" do
  context "when authenticated with bearer token" do
    let(:id) { SecureRandom.uuid }
    let(:failed_import) { create(:failed_import, id:) }

    before do
      allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :provider)
      failed_import
    end

    it "retrieves the import when id matches" do
      get "/v1/failed_imports/#{id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to match(
        {
          "id" => id,
          "provider_id" => failed_import.provider_id,
          "details" => failed_import.details,
          "error_type" => 'UNKNOWN',
          "created_at" => an_instance_of(String),
          "updated_at" => an_instance_of(String),
        },
      )
    end

    it "fails when id does not match" do
      expect { get "/v1/failed_imports/garbage" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
