require "rails_helper"

RSpec.describe PaymentRequests::SearchService do
  before do
    create(:payment_request, :non_standard_magistrate)
  end

  let(:params) { { claim_type: "NsmClaim" } }

  let(:expected_result_as_hash) do
    {
      "metadata" => {
        "total_results" => 1,
        "page" => 1,
        "per_page" => 10,
      },
      "data" => kind_of(Array),
    }
  end

  describe "#call" do
    subject(:call) { described_class.new(params, :caseworker).call }

    it "returns JSON string" do
      expect(call).to be_a(String)
    end

    it "returns JSON of expected structure" do
      expect(JSON.parse(call)).to match(expected_result_as_hash)
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(params, :caseworker) }

    it "returns JSON of expected structure" do
      expect(JSON.parse(call)).to match(expected_result_as_hash)
    end
  end
end
