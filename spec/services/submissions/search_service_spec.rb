require "rails_helper"

RSpec.describe Submissions::SearchService do
  before do
    create(:submission, :with_pa_version, defendant_name: "Fred Yankowitz")
  end

  let(:params) { { application_type: "crm4" } }

  let(:expected_result_as_hash) do
    {
      "metadata" => {
        "total_results" => 1,
        "page" => 1,
        "per_page" => 10,
      },
      "data" => kind_of(Array),
      "raw_data" => kind_of(Array),
    }
  end

  describe "#call" do
    subject(:call) { described_class.new(params).call }

    it "returns JSON string" do
      expect(call).to be_a(String)
    end

    it "returns JSON of expected structure" do
      expect(JSON.parse(call)).to match(expected_result_as_hash)
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(params) }

    it "returns JSON of expected structure" do
      expect(JSON.parse(call)).to match(expected_result_as_hash)
    end
  end
end
