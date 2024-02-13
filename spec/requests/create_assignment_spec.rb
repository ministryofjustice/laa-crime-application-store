require "rails_helper"

RSpec.describe "Create assignment" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  it "assigns a submission to me" do
    submission = create :submission, application_type: "crm4"
    post "/v1/submissions/assignments", params: {
      application_type: "crm4",
      user_id: "123",
    }

    expect(response).to have_http_status(:created)

    expect(submission.reload.assigned_user_id).to eq "123"
    expect(submission.events.first["event_type"]).to eq "assignment"
    expect(response.parsed_body["application_id"]).to eq submission.application_id
  end

  it "assigns nothing if there is nothing to assign" do
    create :submission, application_type: "crm7"
    create :submission, application_type: "crm4", assigned_user_id: "456"
    post "/v1/submissions/assignments", params: {
      application_type: "crm4",
      user_id: "123",
    }

    expect(response).to have_http_status(:not_found)
  end

  it "prefers newer for crm7" do
    newer = create :submission, application_type: "crm7", created_at: 1.hour.ago
    create :submission, application_type: "crm7", created_at: 2.hours.ago
    post "/v1/submissions/assignments", params: {
      application_type: "crm7",
      user_id: "123",
    }

    expect(response.parsed_body["application_id"]).to eq newer.application_id
  end

  context "when handling crm4 cases" do
    context "when there is an older and a newer application" do
      let(:newer_application) { create(:submission, application_type: "crm4", created_at: 1.day.ago) }
      let(:older_application) { create(:submission, application_type: "crm4", created_at: 2.days.ago) }

      before do
        newer_application && older_application
      end

      it "prefers earlier submisions" do
        post "/v1/submissions/assignments", params: { application_type: "crm4", user_id: "123" }
        expect(response.parsed_body["application_id"]).to eq older_application.application_id
      end
    end

    context "when the newer application is a central criminal court case" do
      let(:central_court_application) do
        create(:submission, application_type: "crm4",
                            created_at: 1.day.ago,
                            submission_versions: [build(:submission_version, data: { court_type: "central_criminal_court" })])
      end

      let(:non_central_court_application) do
        create(:submission, application_type: "crm4",
                            created_at: 2.days.ago,
                            submission_versions: [build(:submission_version, data: { court_type: "other" })])
      end

      before do
        central_court_application && non_central_court_application
      end

      it "prefers the central criminal court case" do
        post "/v1/submissions/assignments", params: { application_type: "crm4", user_id: "123" }
        expect(response.parsed_body["application_id"]).to eq central_court_application.application_id
      end
    end

    context "when the newer application used to be a central criminal court case" do
      let(:older_former_central_court_application) do
        create(
          :submission,
          application_type: "crm4",
          created_at: 1.day.ago,
          submission_versions: [
            build(:submission_version, created_at: 1.day.ago, data: { court_type: "central_criminal_court" }),
            build(:submission_version, created_at: 1.hour.ago, data: { court_type: "other" }),
          ],
        )
      end

      let(:newer_non_central_court_application) do
        create(:submission, application_type: "crm4",
                            created_at: 2.days.ago,
                            submission_versions: [build(:submission_version, data: { court_type: "other" })])
      end

      before do
        older_former_central_court_application && newer_non_central_court_application
      end

      it "prefers the central criminal court case" do
        post "/v1/submissions/assignments", params: { application_type: "crm4", user_id: "123" }
        expect(response.parsed_body["application_id"]).to eq newer_non_central_court_application.application_id
      end
    end

    context "when the newer application is a pathology case" do
      let(:pathology_application) do
        create(:submission, application_type: "crm4",
                            created_at: 1.day.ago,
                            submission_versions: [build(:submission_version, data: { service_type: "pathologist" })])
      end

      let(:non_pathology_application) do
        create(:submission, application_type: "crm4",
                            created_at: 2.days.ago,
                            submission_versions: [build(:submission_version, data: { service_type: "other" })])
      end

      before do
        pathology_application && non_pathology_application
      end

      it "prefers the pathology case" do
        post "/v1/submissions/assignments", params: { application_type: "crm4", user_id: "123" }
        expect(response.parsed_body["application_id"]).to eq pathology_application.application_id
      end
    end

    context "when there is a pathology case and a central court case" do
      let(:pathology_application) do
        create(:submission, application_type: "crm4",
                            created_at: 1.day.ago,
                            submission_versions: [build(:submission_version, data: { service_type: "pathologist" })])
      end

      let(:central_court_application) do
        create(:submission, application_type: "crm4",
                            created_at: 2.days.ago,
                            submission_versions: [build(:submission_version, data: { court_type: "central_criminal_court" })])
      end

      before do
        pathology_application && central_court_application
      end

      it "prefers the central criminal court case" do
        post "/v1/submissions/assignments", params: { application_type: "crm4", user_id: "123" }
        expect(response.parsed_body["application_id"]).to eq central_court_application.application_id
      end
    end
  end
end
