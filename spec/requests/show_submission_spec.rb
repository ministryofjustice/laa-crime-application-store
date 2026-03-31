require "rails_helper"

RSpec.describe "Show submission" do
  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role:)
    create(:submission_version, submission:, version: 1, application: { old: :data })
    create(:submission_version, submission:, version: 2, application: { new: :data })
    create(:submission_version, submission:, version: 3, application: { pending: :data }, pending: true)
  end

  let(:role) { :provider }
  let(:submission) { create :submission, current_version: 2 }

  it "returns a submission" do
    get "/v1/submissions/#{submission.id}"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["application_id"]).to eq submission.id
  end

  it "returns the latest non-pending version" do
    get "/v1/submissions/#{submission.id}"

    expect(response.parsed_body["application"]).to eq({ "new" => "data" })
  end

  context "when viewer is a caseworker" do
    let(:role) { :caseworker }

    it "returns the latest version even if it's pending" do
      get "/v1/submissions/#{submission.id}"
      expect(response.parsed_body["application"]).to eq({ "pending" => "data" })
    end
  end
end
