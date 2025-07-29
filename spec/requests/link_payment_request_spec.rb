require "rails_helper"

RSpec.describe "Link payment request" do
  let(:payment_id) { SecureRandom.uuid }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  it "returns not found when trying to link non existing record" do
    expect { patch "/v1/payment_requests/#{SecureRandom.uuid}/link" }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it "fails when the claim is associated with a legacy supplemental claim Submission" do
    create(:payment_request, id: payment_id, submitted_at: nil)
    create(:nsm_claim, laa_reference: "LAA-abc123", submission: create(:submission, :with_supplemental_version, laa_reference: "LAA-abc123"))
    patch "/v1/payment_requests/#{payment_id}/link", params: {
      laa_reference: "LAA-abc123",
    }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  context "when payment request is of type non_standard_mag" do
    let(:request_type) { "non_standard_mag" }

    before { create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil) }

    it "returns 422 when the request includes an laa_reference" do
      patch "/v1/payment_requests/#{payment_id}/link", params: {
        laa_reference: "LAA-abc123",
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns a successful response and links to an NsmClaim" do
      patch "/v1/payment_requests/#{payment_id}/link"

      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id).payable_type).to eq("NsmClaim")
      expect(PaymentRequest.find(payment_id).payable.laa_reference).not_to be_nil
    end
  end

  context "when payment request is of type non_standard_mag_supplemental" do
    let(:request_type) { "non_standard_mag_supplemental" }

    it_behaves_like "a subsequent nsm payment", "non_standard_mag_supplemental"
  end

  context "when payment request is of type non_standard_mag_amendment" do
    let(:request_type) { "non_standard_mag_amendment" }

    it_behaves_like "a subsequent nsm payment", "non_standard_mag_supplemental"
  end

  context "when payment request is of type non_standard_mag_appeal" do
    let(:request_type) { "non_standard_mag_appeal" }

    it_behaves_like "a subsequent nsm payment", "non_standard_mag_appeal"
  end

  context "when payment request is of type assigned_counsel" do
    let(:request_type) { "assigned_counsel" }

    it "returns 422 when trying to link to a non NsmClaim record" do
      create(:assigned_counsel_claim, laa_reference: "LAA-abc123")
      create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil)

      patch "/v1/payment_requests/#{payment_id}/link", params: {
        laa_reference: "LAA-abc123",
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates a payment and unlinked assigned counsel record when no laa ref supplied" do
      create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil)
      patch "/v1/payment_requests/#{payment_id}/link"

      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id).payable.is_a?(AssignedCounselClaim)).to be true
    end

    it "creates a payment and linked assigned counsel record when an NsmClaim laa ref supplied" do
      create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil)
      create(:nsm_claim, laa_reference: "LAA-abc123")

      patch "/v1/payment_requests/#{payment_id}/link", params: {
        laa_reference: "LAA-abc123",
      }
      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id).payable.is_a?(AssignedCounselClaim)).to be true
      expect(PaymentRequest.find(payment_id).payable.nsm_claim.laa_reference).to eq("LAA-abc123")
    end
  end

  context "when payment request is of type assigned counsel appeal" do
    let(:request_type) { "assigned_counsel_appeal" }

    it_behaves_like "a subsequent assigned counsel payment", request_type
  end

  context "when payment request is of type assigned counsel amendment" do
    let(:request_type) { "assigned_counsel_amendment" }

    it_behaves_like "a subsequent assigned counsel payment", request_type
  end
end
