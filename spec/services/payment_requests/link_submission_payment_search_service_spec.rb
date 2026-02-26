require "rails_helper"

RSpec.describe PaymentRequests::LinkSubmissionPaymentsSearchService do
  describe "#call" do
    subject(:call_service) { described_class.new(params, :caseworker).call }

    context "when payment requests match the search parameters" do
      let!(:payment_request) { create(:payment_request, :non_standard_magistrate) }
      let(:params) { { query: payment_request.payment_request_claim.laa_reference } }

      it "returns payment request data" do
        parsed = JSON.parse(call_service)

        expect(parsed.dig("metadata", "total_results")).to eq(1)
        expect(parsed.dig("data", 0, "request_type")).to eq(payment_request.request_type)
      end
    end

    context "when no payment requests match but CRM7 submissions exist" do
      let(:search_reference) { "LAA-CRM7001" }
      let(:params) { { query: search_reference, per_page: 5 } }

      before do
        create(:submission, :with_nsm_version, laa_reference: search_reference)
      end

      it "falls back to the CRM7 submission search" do
        parsed = JSON.parse(call_service)

        expect(parsed.dig("metadata", "total_results")).to eq(1)
        expect(parsed.dig("data", 0, "request_type")).to eq("crm7")
        expect(parsed.dig("data", 0, "payment_request_claim", "laa_reference")).to eq(search_reference)
      end
    end

    context "when no payment requests or CRM7 submissions match" do
      let(:params) { { query: "LAA-NOTFOUND" } }

      it "returns an empty result set" do
        parsed = JSON.parse(call_service)

        expect(parsed.dig("metadata", "total_results")).to eq(0)
        expect(parsed["data"]).to eq([])
      end
    end
  end

  describe ".call" do
    subject(:class_call) { described_class.call(params, :caseworker) }

    let!(:payment_request) { create(:payment_request, :non_standard_magistrate) }
    let(:params) { { query: payment_request.payment_request_claim.laa_reference } }

    it "delegates to the instance call" do
      parsed = JSON.parse(class_call)

      expect(parsed.dig("metadata", "total_results")).to eq(1)
    end
  end
end
