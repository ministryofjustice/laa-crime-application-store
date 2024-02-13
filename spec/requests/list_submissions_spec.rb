require "rails_helper"

RSpec.describe "List submissions" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  let(:returned_ids) { response.parsed_body["applications"].map { _1["application_id"] } }

  it "returns submissions" do
    create :submission
    get "/v1/submissions"

    expect(response.parsed_body["applications"].length).to eq 1
    expect(response.parsed_body["total"]).to eq 1
  end

  it "paginates submissions" do
    create_list :submission, 15, updated_at: 1.day.ago
    very_recent = create :submission, updated_at: 1.hour.ago
    very_old = create :submission, updated_at: 2.days.ago

    get "/v1/submissions", params: { page: 2, count: 10 }

    expect(response.parsed_body["applications"].length).to eq 7
    expect(response.parsed_body["total"]).to eq 17
    expect(returned_ids).to include(very_recent.application_id)
    expect(returned_ids).not_to include(very_old.application_id)
  end

  it "allows filtering by type" do
    crm4 = create :submission, application_type: "crm4"
    crm7 = create :submission, application_type: "crm7"

    get "/v1/submissions", params: { application_type: "crm4" }

    expect(returned_ids).to include(crm4.application_id)
    expect(returned_ids).not_to include(crm7.application_id)
  end

  it "allows filtering by assessed" do
    granted = create :submission, application_state: "granted"
    submitted = create :submission, application_type: "submitted"

    get "/v1/submissions", params: { assessed: "true" }

    expect(returned_ids).to include(granted.application_id)
    expect(returned_ids).not_to include(submitted.application_id)
  end

  it "allows filtering by *not* assessed" do
    granted = create :submission, application_state: "granted"
    submitted = create :submission, application_type: "submitted"

    get "/v1/submissions", params: { assessed: "false" }

    expect(returned_ids).to include(submitted.application_id)
    expect(returned_ids).not_to include(granted.application_id)
  end

  it "allows filtering by last updated" do
    older = create :submission, updated_at: 1.day.ago
    newer = create :submission, updated_at: 1.hour.ago

    get "/v1/submissions", params: { since: 4.hours.ago.to_i }

    expect(returned_ids).to include(newer.application_id)
    expect(returned_ids).not_to include(older.application_id)
  end

  it "allows filtering by assigned user" do
    assigned = create :submission, assigned_user_id: "123123"
    unassigned = create :submission, assigned_user_id: nil
    assigned_to_other = create :submission, assigned_user_id: "456456456"

    get "/v1/submissions", params: { assigned_user_id: "123123" }

    expect(returned_ids).to include(assigned.application_id)
    expect(returned_ids).not_to include(unassigned.application_id)
    expect(returned_ids).not_to include(assigned_to_other.application_id)
  end
end
