RSpec.shared_examples "a subsequent nsm payment" do |request_type|
  let(:payment_id) { SecureRandom.uuid }

  it "fails when no laa reference is supplied" do
    create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil)
    patch "/v1/payment_requests/#{payment_id}/link"

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "fails when laa reference is supplied but doesn't link to an NsmClaim" do
    create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil)
    patch "/v1/payment_requests/#{payment_id}/link", params: {
      laa_reference: "LAA-abc123",
    }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "is successful and links NsmClaim when a record with the laa reference exists" do
    create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil)
    create(:nsm_claim, laa_reference: "LAA-abc123")
    patch "/v1/payment_requests/#{payment_id}/link", params: {
      laa_reference: "LAA-abc123",
    }

    expect(response).to have_http_status(:created)
    expect(PaymentRequest.find(payment_id).payable.laa_reference).to eq("LAA-abc123")
  end
end
