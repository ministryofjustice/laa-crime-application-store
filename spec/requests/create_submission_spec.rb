require "rails_helper"

RSpec.describe "Create submission" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  let(:created_record) { Submission.last }

  it "saves what I send" do
    post "/v1/submissions", params: {
      application_id: "123123123",
      application_type: "crm4",
      application_risk: "low",
      json_schema_version: 1,
      application: { foo: :bar },
    }
    expect(response).to have_http_status :created

    expect(created_record).to have_attributes(
      application_id: "123123123",
      application_state: "submitted",
      application_type: "crm4",
      application_risk: "low",
    )

    expect(created_record.events.first["event_type"]).to eq "new_version"

    expect(created_record.current_version).to have_attributes(
      json_schema_version: 1,
      data: { "foo" => "bar" },
    )
  end

  it "validates what I send" do
    post "/v1/submissions", params: {
      application_id: "123123123",
    }
    expect(response).to have_http_status :unprocessable_entity
  end
end
