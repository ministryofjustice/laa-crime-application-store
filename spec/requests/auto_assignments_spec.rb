require "rails_helper"

RSpec.describe "Auto-assignments" do
  let(:caseworker_id) { SecureRandom.uuid }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  describe "PA" do
    let(:submission) { create :submission, :with_pa_version, last_updated_at: 2.days.ago }

    before { submission }

    context "when the submission is assignable" do
      it "assigns and returns the submission" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
        expect(response).to have_http_status :created
        expect(submission.reload.assigned_user_id).to eq caseworker_id
        expect(response.parsed_body["application_id"]).to eq submission.id
      end
    end

    context "when only candidate submission is in wrong state" do
      before { submission.update!(state: "sent_back") }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when only candidate submission is already assigned" do
      let(:existing) { SecureRandom.uuid }

      before { submission.update!(assigned_user_id: existing) }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to eq existing
      end
    end

    context "when only candidate submission has previously been unassigned from current user" do
      before { submission.update!(unassigned_user_ids: [SecureRandom.uuid, caseworker_id]) }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when only candidate submission is wrong type" do
      before { submission.update!(application_type: "crm7") }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when there is a slightly older submission" do
      let(:older_submission) { create :submission, :with_pa_version, last_updated_at: (2.days.ago - 5.minutes) }

      before { older_submission }

      it "assigns the older one" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
        expect(response.parsed_body["application_id"]).to eq older_submission.id
      end

      context "when the newer is a post mortem pathologist report" do
        before do
          submission.latest_version.update!(
            application: {
              service_type: "pathologist_report",
              quotes: [{ related_to_post_mortem: true }],
            },
          )
        end

        it "assigns the newer one" do
          post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
          expect(response.parsed_body["application_id"]).to eq submission.id
        end

        context "when the older is in the central criminal court" do
          before do
            older_submission.latest_version.update!(
              application: {
                court_type: "central_criminal_court",
              },
            )
          end

          it "assigns the older one" do
            post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
            expect(response.parsed_body["application_id"]).to eq older_submission.id
          end
        end

        context "when the non-central-criminal-court one is from the previous day" do
          before do
            submission.update!(last_updated_at: 3.days.ago)
          end

          it "assigns the non-central-criminal-court one" do
            post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm4" }
            expect(response.parsed_body["application_id"]).to eq submission.id
          end
        end
      end
    end
  end

  describe "NSM" do
    let(:submission) { create :submission, :with_nsm_version, last_updated_at: 2.days.ago }

    before { submission }

    context "when the submission is assignable" do
      it "assigns and returns the submission" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :created
        expect(submission.reload.assigned_user_id).to eq caseworker_id
        expect(response.parsed_body["application_id"]).to eq submission.id
      end
    end

    context "when only candidate submission is in wrong state" do
      before { submission.update!(state: "sent_back") }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when only candidate submission is already assigned" do
      let(:existing) { SecureRandom.uuid }

      before { submission.update!(assigned_user_id: existing) }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to eq existing
      end
    end

    context "when only candidate submission has previously been unassigned from current user" do
      before { submission.update!(unassigned_user_ids: [SecureRandom.uuid, caseworker_id]) }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when only candidate submission is wrong type" do
      before { submission.update!(application_type: "crm4") }

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when there is no cost summary and risk is high" do
      before do
        submission.update!(application_risk: "high")
        submission.latest_version.update!(application: { foo: :bar })
      end

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when there is no cost summary and risk is medium" do
      before do
        submission.update!(application_risk: "medium")
        submission.latest_version.update!(application: { foo: :bar })
      end

      it "assigns it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :created
        expect(submission.reload.assigned_user_id).to eq caseworker_id
      end
    end

    context "when there is a cost summary with gross profit cost below threshold" do
      before do
        submission.latest_version.update!(application: { cost_summary: { profit_costs: { gross_cost: "4999.99" } } })
      end

      it "assigns it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :created
        expect(submission.reload.assigned_user_id).to eq caseworker_id
      end
    end

    context "when there is a cost summary with gross profit cost at threshold" do
      before do
        submission.latest_version.update!(application: { cost_summary: { profit_costs: { gross_cost: "5000.00" } } })
      end

      it "does not assign it" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response).to have_http_status :not_found
        expect(submission.reload.assigned_user_id).to be_nil
      end
    end

    context "when there is an older submission" do
      let(:older_submission) { create :submission, :with_nsm_version, last_updated_at: (2.days.ago - 5.minutes) }

      before { older_submission }

      it "assigns the older one" do
        post "/v1/submissions/auto_assignments", params: { current_user_id: caseworker_id, application_type: "crm7" }
        expect(response.parsed_body["application_id"]).to eq older_submission.id
      end
    end
  end
end
