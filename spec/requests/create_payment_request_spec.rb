require "rails_helper"

RSpec.describe "Create payment request" do
  let(:submitted_date) { Time.zone.local(2025, 1, 1) }
  let(:submitter_id) { SecureRandom.uuid }
  let(:request_type) { "non_standard_mag" }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  it "can create payment request with valid params" do
    post "/v1/payment_requests", params: {
      submitter_id:,
      request_type:,
    }

    expect(response).to have_http_status(:created)
  end

  context "when submitter_id is invalid" do
    let(:submitter_id) { "garbage" }

    it "returns a 422 error" do
      post "/v1/payment_requests", params: {
        submitter_id:,
        request_type:,
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when request_type is invalid" do
    let(:request_type) { "garbage" }

    it "returns a 422 error" do
      post "/v1/payment_requests", params: {
        submitter_id:,
        request_type:,
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when laa_reference is supplied" do
    let(:laa_reference) { "LAA-abc123" }

    context "when request type is non_standard_mag" do
      let(:request_type) { "non_standard_mag" }

      context "when submission can't be linked" do
        before { allow(PaymentRequests::LinkPayableService).to receive(:call).and_raise(PaymentLinkError) }

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when submission can be linked" do
        before { allow(PaymentRequests::LinkPayableService).to receive(:call).and_return(true) }

        it "has a successful response" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:created)
        end
      end

      context "when no submission exists for the given laa reference" do
        before do
          create(:submission, :with_nsm_version, state: "granted", laa_reference: "LAA-xyz123")
        end

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when the submission exists for the laa reference but it's the wrong type" do
        before do
          create(:submission, :with_pa_version, state: "granted", laa_reference: laa_reference)
        end

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when a valid nsm submission exists for the laa reference" do
        let(:submission_id) { SecureRandom.uuid }

        before do
          create(:submission,
                 :with_nsm_version,
                 id: submission_id,
                 state: "granted",
                 account_number: "AAABBB",
                 laa_reference: laa_reference,
                 defendant_name: "Jim Jones")
        end

        it "succeeds and creates/links/autopopulates the correct records" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          built_submission = Submission.first
          PaymentRequest.first
          built_claim = NsmClaim.first

          expect(response).to have_http_status(:created)

          expect(built_submission.latest_version.application["laa_reference"]).to eq(laa_reference)

          expect(built_claim.submission.id).to eq(submission_id)
          expect(built_claim).to have_attributes({
            office_code: built_submission.latest_version.application["office_code"],
            laa_reference: built_submission.latest_version.application["laa_reference"],
            ufn: built_submission.latest_version.application["ufn"],
            stage_code: built_submission.latest_version.application["stage_reached"],
            client_surname: "Jones",
            case_concluded_date: Time.zone.parse(built_submission.latest_version.application["work_completed_date"]),
            court_name: built_submission.latest_version.application["court"],
            court_attendances: built_submission.latest_version.application["number_of_hearing"],
            no_of_defendants: built_submission.latest_version.application["defendants"].count,
          })
        end
      end

      context "when the submission that exists for the laa reference is prior authority" do
        before do
          create(:submission, :with_pa_version, laa_reference: laa_reference)
        end

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when request type is not non_standard_mag" do
      let(:request_type) { "assigned_counsel" }

      it "returns a 422 error" do
        post "/v1/payment_requests", params: {
          submitter_id:,
          request_type:,
          laa_reference:,
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
