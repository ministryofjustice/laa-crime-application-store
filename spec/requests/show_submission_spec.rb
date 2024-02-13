require "rails_helper"

RSpec.describe "Show submission" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  it "returns a submission" do
    submission = create :submission
    get "/v1/submissions/#{submission.application_id}"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["application_id"]).to eq submission.application_id
  end

  it "returns the latest version" do
    submission = create :submission, submission_versions: [
      build(:submission_version, created_at: 2.hours.ago, data: { old: :data }),
      build(:submission_version, created_at: 1.hour.ago, data: { new: :data }),
    ]

    get "/v1/submissions/#{submission.application_id}"

    expect(response.parsed_body["application"]).to eq({ "new" => "data" })
  end
end
