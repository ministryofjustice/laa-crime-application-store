require "rails_helper"

RSpec.describe "List submissions" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(true) }

  let(:returned_ids) { response.parsed_body["applications"].map { _1["application_id"] } }

  it "returns submissions" do
    create :submission
    get "/v1/submissions"

    expect(response.parsed_body["applications"].length).to eq 1
  end

  it "limits by count submissions, retaining oldest" do
    create_list :submission, 15, updated_at: 1.day.ago
    very_recent = create :submission, updated_at: 1.hour.ago
    very_old = create :submission, updated_at: 2.days.ago

    get "/v1/submissions", params: { count: 10 }

    expect(response.parsed_body["applications"].length).to eq 10
    expect(returned_ids).to include(very_old.id)
    expect(returned_ids).not_to include(very_recent.id)
  end

  it "allows filtering by last updated" do
    older = create :submission, updated_at: 1.day.ago
    newer = create :submission, updated_at: 1.hour.ago

    get "/v1/submissions", params: { since: 4.hours.ago.to_i }

    expect(returned_ids).to include(newer.id)
    expect(returned_ids).not_to include(older.id)
  end
end
