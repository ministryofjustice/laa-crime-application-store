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

    %i[caseworker provider].each do |role|
      it "does not perform N+1 application_version lookups for #{role} role" do
        create_list(:submission, 3, :with_pa_version)

        sql_queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          next if payload[:name] == "SCHEMA"

          sql_queries << payload[:sql]
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          described_class.call(params, role)
        end

        n_plus_one_queries = sql_queries.grep(
          /FROM "application_version" WHERE "application_version"\."application_id" = .* ORDER BY "application_version"\."version" DESC LIMIT/,
        )

        expect(n_plus_one_queries).to be_empty
      end
    end
  end
end
