require "rails_helper"

RSpec.describe "Show submission" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :provider) }

  it "returns a submission" do
    submission = create(:submission)
    get "/v1/submissions/#{submission.id}"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["application_id"]).to eq submission.id
  end

  it "returns the latest version" do
    submission = create(:submission, current_version: 2)
    create(:submission_version, submission:, version: 1, application: { old: :data })
    create(:submission_version, submission:, version: 2, application: { new: :data })

    get "/v1/submissions/#{submission.id}"

    expect(response.parsed_body["application"]).to eq({ "new" => "data" })
  end
end
