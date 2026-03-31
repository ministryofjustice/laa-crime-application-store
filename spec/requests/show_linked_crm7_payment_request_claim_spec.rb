require "rails_helper"

RSpec.describe "linked CRM7 payment request search", type: :request do
  let(:search_endpoint) { "/v1/linked_claim/searches" }

  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with a CRM7 submission claim" do
    let!(:submission) do
      create(:submission, :with_nsm_version,
             state: "granted",
             status: "granted",
             laa_reference: "LAA-CRM7001")
    end
    let(:search_reference) { submission.ordered_submission_versions.first.application["laa_reference"] }
    let(:crm7_params) { { query: search_reference, request_type: "non_standard_magistrate" } }

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
    post search_endpoint, params: { query: "LAA-NOTFOUND", request_type: "non_standard_magistrate" }

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

      expect(response).to have_http_status(:no_content)
    end
  end
end
