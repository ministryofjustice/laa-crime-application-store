require "rails_helper"

RSpec.describe "Adjust submission" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  it "lets me update data by creating a new version" do
    submission = create :submission,
                        submission_versions: [build(:submission_version, data: { old: :data })]
    post "/v1/submissions/#{submission.application_id}/adjustments", params: { application: { new: :data }, json_schema_version: 1 }
    expect(response).to have_http_status(:created)
    expect(submission.reload.current_version_number).to eq 2
    expect(submission.reload.current_version.data).to eq({ "new" => "data" })
  end

  it "adds metadata" do
    submission = create :submission
    post "/v1/submissions/#{submission.application_id}/adjustments",
         params: {
           application: { new: :data },
           json_schema_version: 1,
           change_detail_sets: %w[foo bar],
           user_id: "123",
           linked_id: "21",
           linked_type: "foo",
         }

    expect(submission.reload.events.count).to eq 2
    expect(submission.reload.events.first).to include(
      "event_type" => "edit",
      "linked_id" => "21",
      "linked_type" => "foo",
      "primary_user_id" => "123",
      "details" => "foo",
    )
  end

  it "validates" do
    submission = create :submission,
                        submission_versions: [build(:submission_version, data: { old: :data })]
    post "/v1/submissions/#{submission.application_id}/adjustments", params: { application: { new: :data }, json_schema_version: nil }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
