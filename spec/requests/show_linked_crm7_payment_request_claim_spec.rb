require "rails_helper"

RSpec.describe "linked CRM7 payment request search", type: :request do
  let(:search_endpoint) { "/v1/linked_claim/searches" }

  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with a CRM7 submission claim" do
    let(:submission) { create(:submission, :with_nsm_version) }
    let(:search_reference) { submission.ordered_submission_versions.first.application["laa_reference"] }
    let(:crm7_params) { { query: search_reference } }
    let(:service_response) do
      {
        metadata: { total_results: 1, page: 1, per_page: 10 },
        data: [
          {
            submission_id: submission.id,
            type: "Crm7SubmissionClaim",
            laa_reference: search_reference,
          },
        ],
      }.to_json
    end

    before do
      allow(PaymentRequests::LinkSubmissionPaymentsSearchService)
        .to receive(:call).with(hash_including(query: search_reference), :caseworker).and_return(service_response)
    end

    it "successfully makes the request" do
      post search_endpoint, params: crm7_params
      expect(response).to have_http_status(:created)
    end

    it "returns CRM7 search results with claim data" do
      post search_endpoint, params: crm7_params

      result = response.parsed_body.fetch("data").first
      expect(result).to include(
        "submission_id" => submission.id,
        "type" => "Crm7SubmissionClaim",
        "laa_reference" => search_reference,
      )
    end

    it "returns metadata about the CRM7 result" do
      post search_endpoint, params: crm7_params

      expect(response.parsed_body.fetch("metadata")).to include(
        "total_results" => 1,
        "page" => 1,
      )
    end
  end

  it "returns an empty result set when not found" do
    allow(PaymentRequests::LinkSubmissionPaymentsSearchService)
      .to receive(:call).and_return({ metadata: { total_results: 0, page: 1, per_page: 10 }, data: [] }.to_json)

    post search_endpoint, params: { query: "LAA-NOTFOUND" }

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("metadata", "total_results")).to eq(0)
    expect(response.parsed_body["data"]).to eq([])
  end

  context "when the search service raises an error" do
    before do
      allow(PaymentRequests::LinkSubmissionPaymentsSearchService).to receive(:call).and_raise(StandardError, "boom")
    end

    it "returns a helpful error response" do
      post search_endpoint, params: { query: "LAA-FAIL" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["message"]).to include("boom")
    end
  end
end
