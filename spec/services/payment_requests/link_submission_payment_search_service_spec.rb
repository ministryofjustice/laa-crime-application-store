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
        expect(parsed.dig("data", 0, "laa_reference")).to eq(payment_request.payment_request_claim.laa_reference)
        expect(parsed.dig("data", 0, "type")).to eq("NsmClaim")
      end
    end

    context "when no payment requests match but CRM7 submissions exist" do
      let(:search_reference) { "LAA-CRM7001" }
      let(:params) { { query: search_reference, per_page: 5 } }
      let(:crm7_raw_record) do
        {
          application_id: SecureRandom.uuid,
          application: {
            laa_reference: search_reference,
            firm_office: { account_number: "1A123B", name: "Firm" },
            defendants: [{ first_name: "Jane", last_name: "Doe", main: true }],
            ufn: "120223/001",
          },
        }
      end
      let(:submissions_service) do
        instance_double(
          Submissions::SearchService,
          call: {
            metadata: { total_results: 1, page: 1, per_page: 5 },
            raw_data: [crm7_raw_record],
          }.to_json,
        )
      end

      before do
        allow(Submissions::SearchService).to receive(:new).and_return(submissions_service)
      end

      it "falls back to the CRM7 submission search" do
        parsed = JSON.parse(call_service)

        expect(parsed.dig("metadata", "total_results")).to eq(1)
        expect(parsed.dig("data", 0, "type")).to eq("Crm7SubmissionClaim")
        expect(parsed.dig("data", 0, "laa_reference")).to eq(search_reference)
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

    context "when CRM7 submissions have mixed statuses" do
      let!(:granted_submission) do
        create(:submission, :with_nsm_version,
               state: "granted",
               status: "granted",
               laa_reference: "LAA-GRANTED")
      end
      let!(:part_grant_submission) do
        create(:submission, :with_nsm_version,
               state: "part_grant",
               status: "part_grant",
               laa_reference: "LAA-PART")
      end
      let!(:rejected_submission) do
        create(:submission, :with_nsm_version,
               state: "rejected",
               status: "rejected",
               laa_reference: "LAA-REJECTED")
      end
      let(:params) { { query: nil } }

      it "only returns granted and part-grant CRM7 submissions" do
        parsed = JSON.parse(call_service)

        expect(parsed.dig("metadata", "total_results")).to eq(2)
        expect(parsed.fetch("data").map { _1["laa_reference"] })
          .to match_array(%w[LAA-GRANTED LAA-PART])
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

RSpec.describe PaymentRequests::LinkSubmissionPayments::PaymentRequestsSearch do
  subject(:search) { described_class.new(search_params, :caseworker) }

  describe "#call" do
    context "with a multi-token query" do
      let!(:claim) do
        create(
          :payment_request_claim,
          laa_reference: "LAA-TOKEN",
          ufn: "120223/001",
          solicitor_office_code: "1A123B",
          client_last_name: "smith",
        )
      end

      let(:search_params) { { query: "LAA-TOKEN 120223/001 1A123B Smith" } }

      it "applies all classifiers" do
        parsed = JSON.parse(search.call)
        expect(parsed.dig("metadata", "total_results")).to eq(1)
      end
    end

    context "with only a client name" do
      let!(:claim) { create(:payment_request_claim, client_last_name: "carter") }
      let(:search_params) { { query: "carter" } }

      it "skips the laa_reference filter" do
        parsed = JSON.parse(search.call)
        expect(parsed.dig("metadata", "total_results")).to eq(1)
      end
    end
  end

  describe "#results?" do
    context "with matching claims" do
      let!(:claim) { create(:payment_request_claim, laa_reference: "LAA-FINDME") }
      let(:search_params) { { query: "LAA-FINDME" } }

      it "returns true after call" do
        search.call
        expect(search.results?).to be(true)
      end
    end

    context "without matches" do
      let(:search_params) { { query: "LAA-MISSING" } }

      it "returns false after call" do
        search.call
        expect(search.results?).to be(false)
      end
    end
  end

  describe "#query_params" do
    let(:search_params) { { query: "LAA-CRM7001 120223/001 1A123B Smith" } }

    it "extracts structured tokens" do
      expect(search.send(:query_params)).to eq(
        laa_reference: "laa-crm7001",
        ufn: "120223/001",
        office_code: "1a123b",
        client_last_name: "smith",
      )
    end
  end

  describe "#query_params when query missing" do
    let(:search_params) { {} }

    it "returns an empty hash" do
      expect(search.send(:query_params)).to eq({})
    end
  end

  describe "#sort_clause" do
    context "when column requires lower-casing" do
      let(:search_params) { { sort_by: "laa_reference", sort_direction: "Descending" } }

      it "builds a LOWER(...) clause with normalized direction" do
        expect(search.send(:sort_clause)).to eq("LOWER(payment_request_claims.laa_reference) desc")
      end
    end

    context "when column is created_at" do
      let(:search_params) { { sort_by: "created_at", sort_direction: "ascending" } }

      it "returns a direct column clause" do
        expect(search.send(:sort_clause)).to eq("created_at asc")
      end
    end

    context "when column is not sortable" do
      let(:search_params) { { sort_by: "invalid", sort_direction: "asc" } }

      it "raises an error" do
        expect { search.send(:sort_clause) }.to raise_error(/Unsortable column "invalid"/)
      end
    end
  end
end

RSpec.describe Submissions::LinkSubmissionPayments::Crm7Search do
  subject(:service) { described_class.new(search_params, :caseworker) }

  let(:search_params) { { query: "LAA-CRM7001", page: 2, per_page: 3 } }

  describe "#call" do
    context "when claim type is excluded" do
      let(:search_params) { super().merge(claim_type: "assigned_counsel_amendment") }

      it "skips the submissions search" do
        expect(Submissions::SearchService).not_to receive(:new)
        expect(service.call).to be_nil
      end
    end

    context "when the submissions search returns no results" do
      let(:search_service) do
        instance_double(Submissions::SearchService,
                        call: { metadata: { total_results: 0 }, raw_data: [] }.to_json)
      end

      before do
        allow(Submissions::SearchService).to receive(:new).and_return(search_service)
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end
    end

    context "when CRM7 data is present" do
      let(:raw_record) do
        {
          application_id: "sub-123",
          application: {
            laa_reference: "LAA-CRM7001",
            firm_office: { account_number: "1A123B", name: "Firm" },
            defendants: [{ first_name: "Jane", last_name: "Doe", main: true }],
            ufn: "120223/001",
          },
        }
      end

      let(:search_service) do
        instance_double(Submissions::SearchService,
                        call: { metadata: { total_results: 1 }, raw_data: [raw_record] }.to_json)
      end

      before do
        allow(Submissions::SearchService).to receive(:new).and_return(search_service)
        stub_const(
          "Crm7SearchResultsResource",
          Class.new do
            def initialize(results)
              @results = results
            end

            def as_json(*)
              @results.map(&:laa_reference)
            end
          end,
        )
      end

      it "serializes the CRM7 results" do
        parsed = JSON.parse(service.call)

        expect(parsed["metadata"]).to include("total_results" => 1, "page" => 2, "per_page" => 3)
        expect(parsed["data"]).to eq(["LAA-CRM7001"])
      end

      it "limits the submissions search to granted statuses" do
        expect(Submissions::SearchService).to receive(:new)
          .with(hash_including(status_with_assignment: %w[part_grant granted]), :caseworker)
          .and_return(search_service)

        service.call
      end
    end

    context "when CRM7 raw data is empty" do
      let(:search_service) do
        instance_double(Submissions::SearchService,
                        call: { metadata: { total_results: 1 }, raw_data: [] }.to_json)
      end

      before do
        allow(Submissions::SearchService).to receive(:new).and_return(search_service)
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end
    end
  end

  describe "#crm7_search_params" do
    let(:search_params) { { sort_by: "created_at", sort_direction: "desc" } }

    it "filters keys and sets defaults" do
      params = service.send(:crm7_search_params)

      expect(params[:application_type]).to eq("crm7")
      expect(params[:sort_by]).to be_nil
      expect(params[:page]).to eq(1)
      expect(params[:per_page]).to eq(10)
      expect(params[:status_with_assignment]).to eq(%w[part_grant granted])
    end

    it "always restricts statuses to grants even when callers pass other statuses" do
      service_with_status = described_class.new({ status_with_assignment: %w[rejected granted] }, :caseworker)
      params = service_with_status.send(:crm7_search_params)

      expect(params[:status_with_assignment]).to eq(%w[part_grant granted])
    end
  end
end

RSpec.describe BaseSearchService do
  let(:client_role) { :caseworker }

  class DummySearchService < BaseSearchService
    def search_query
      []
    end

    def search_results
      { offset: offset, limit: limit, per_page: per_page, page: page }
    end
  end

  describe "#call" do
    it "calculates pagination offsets" do
      result = DummySearchService.new({ page: 2, per_page: 5 }, client_role).call

      expect(result).to eq(offset: 5, limit: 5, per_page: 5, page: 2)
    end

    it "defaults pagination values" do
      result = DummySearchService.new({}, client_role).call

      expect(result).to eq(offset: 0, limit: 10, per_page: 10, page: 1)
    end

    it "raises when search_query is not implemented" do
      expect { BaseSearchService.new({}, client_role).send(:search_query) }
        .to raise_error(NoMethodError, /method not found/)
    end

    it "raises when search_results is not implemented" do
      expect { BaseSearchService.new({}, client_role).send(:search_results) }
        .to raise_error(NoMethodError, /method not found/)
    end
  end
end

RSpec.describe Crm7SubmissionClaim do
  let(:application_data) do
    {
      laa_reference: "LAA-CRM7001",
      ufn: "120223/001",
      firm_office: { account_number: "1A123B", name: "Firm & Sons" },
      defendants: [
        { first_name: "Jane", last_name: "Roe", main: "false" },
        { first_name: "John", last_name: "Doe", main: "true" },
      ],
      work_completed_date: Date.new(2024, 1, 1),
      matter_type: "13",
      youth_court: true,
      stage_reached: "PROG",
      stage_code: nil,
      outcome_code: nil,
      hearing_outcome: "CP17",
      court_attendances: 2,
      defendants_count: 2,
      court: "Ely",
    }
  end

  let(:raw_payload) do
    {
      id: "sub-123",
      created_at: Time.zone.parse("2024-01-01"),
      last_updated_at: Time.zone.parse("2024-01-02"),
      application: application_data,
    }
  end

  subject(:claim) { described_class.new(raw_payload) }

  it "derives identifiers and solicitor details" do
    expect(claim.id).to eq("sub-123")
    expect(claim.submission_id).to eq("sub-123")
    expect(claim.laa_reference).to eq("LAA-CRM7001")
    expect(claim.solicitor_office_code).to eq("1A123B")
    expect(claim.solicitor_firm_name).to eq("Firm & Sons")
  end

  it "selects the main defendant" do
    expect(claim.client_first_name).to eq("John")
    expect(claim.client_last_name).to eq("Doe")
  end

  it "counts defendants and exposes application metrics" do
    expect(claim.no_of_defendants).to eq(2)
    expect(claim.court_attendances).to eq(2)
    expect(claim.ufn).to eq("120223/001")
  end

  it "derives stage and outcome codes with fallbacks" do
    expect(claim.stage_code).to eq("PROG")
    expect(claim.outcome_code).to eq("CP17")
  end

  it "exposes timestamps and defaults" do
    expect(claim.created_at).to eq(Time.zone.parse("2024-01-01"))
    expect(claim.updated_at).to eq(Time.zone.parse("2024-01-02"))
    expect(claim.payment_requests).to eq([])
    expect(claim.nsm_claim).to be_nil
  end

  it "exposes additional application attributes" do
    expect(claim.work_completed_date).to eq(Date.new(2024, 1, 1))
    expect(claim.matter_type).to eq("13")
    expect(claim.youth_court).to be(true)
    expect(claim.court_name).to eq("Ely")
    expect(claim.assigned_counsel_claim).to be_nil
  end

  context "when defendants array is empty" do
    let(:application_data) do
      {
        laa_reference: "LAA-CRM7001",
        ufn: "120223/001",
        firm_office: { account_number: "1A123B", name: "Firm & Sons" },
        defendant: { first_name: "Solo", last_name: "Person" },
      }
    end

    it "falls back to the single defendant" do
      expect(claim.client_first_name).to eq("Solo")
      expect(claim.client_last_name).to eq("Person")
    end
  end

  context "when defendant data is missing" do
    let(:application_data) { {} }

    it "returns nil names" do
      expect(claim.client_first_name).to be_nil
      expect(claim.client_last_name).to be_nil
    end
  end

  context "when defendants include scalar values" do
    let(:application_data) { { defendants: ["legacy-string"] } }

    it "preserves scalar entries" do
      expect(claim.send(:defendants)).to eq(["legacy-string"])
    end
  end

  context "when legacy defendant attribute is nil" do
    let(:application_data) { { defendants: [], defendant: nil } }

    it "returns nil" do
      expect(claim.send(:main_defendant)).to be_nil
    end
  end

  context "when application is a Submission" do
    let(:submission) { create(:submission, :with_nsm_version) }

    it "symbolizes the payload" do
      expect(described_class.new(submission).laa_reference).to eq(submission.latest_version.application["laa_reference"])
    end
  end

  context "when stage data is missing" do
    let(:application_data) { super().merge(stage_reached: nil, stage_code: nil, claim_type: "nsm") }

    it "falls back to the claim_type" do
      expect(claim.stage_code).to eq("nsm")
    end
  end

  context "when updated_at is missing" do
    let(:raw_payload) { super().merge(last_updated_at: nil, updated_at: Time.zone.parse("2024-03-03")) }

    it "uses the provided updated_at" do
      expect(claim.updated_at).to eq(Time.zone.parse("2024-03-03"))
    end
  end
end

RSpec.describe Crm7SearchResult do
  let(:raw_record) do
    {
      application_id: "app-123",
      application_type: "crm7",
      application: {
        laa_reference: "LAA-CRM7001",
        firm_office: { account_number: "1A123B", name: "Firm" },
        defendants: [{ first_name: "Jane", last_name: "Doe", main: true }],
        ufn: "120223/001",
      },
    }
  end

  subject(:result) { described_class.new(raw_record) }

  it "exposes identifiers and delegates claim data" do
    expect(result.id).to eq("app-123")
    expect(result.submission_id).to eq("app-123")
    expect(result.laa_reference).to eq("LAA-CRM7001")
    expect(result.ufn).to eq("120223/001")
    expect(result.type).to eq("Crm7SubmissionClaim")
  end

  it "exposes solicitor and defendant information" do
    expect(result.solicitor_office_code).to eq("1A123B")
    expect(result.solicitor_firm_name).to eq("Firm")
    expect(result.defendant_last_name).to eq("Doe")
  end

  it "exposes request metadata and the raw application" do
    expect(result.request_type).to eq("crm7")
    expect(result.send(:application)).to include(:laa_reference)
  end

  context "when application_id is missing" do
    let(:raw_record) { super().merge(application_id: nil, id: "fallback-id") }

    it "falls back to the id key" do
      expect(result.id).to eq("fallback-id")
    end
  end
end
