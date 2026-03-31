require "rails_helper"

RSpec.describe "Link submission payment search services" do
  describe PaymentRequests::LinkSubmissionPaymentsSearchService do
    describe "#call" do
      subject(:call_service) { described_class.new(params, :caseworker).call }

      let(:request_type) { "non_standard_magistrate" }

      context "when payment requests match the search parameters" do
        let(:payment_request) { create(:payment_request, :non_standard_magistrate) }
        let(:params) do
          {
            query: payment_request.payable_claim.laa_reference,
            request_type: payment_request.request_type,
          }
        end

        it "returns payment request data" do
          parsed = JSON.parse(call_service)

          expect(parsed.dig("metadata", "total_results")).to eq(1)
          expect(parsed.dig("data", 0, "laa_reference")).to eq(payment_request.payable_claim.laa_reference)
          expect(parsed.dig("data", 0, "type")).to eq("NsmClaim")
        end
      end

      context "when no payment requests match but CRM7 submissions exist" do
        let(:search_reference) { "LAA-CRM7001" }
        let(:params) { { query: search_reference, per_page: 5, request_type: } }
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
        let(:params) { { query: "LAA-NOTFOUND", request_type: } }

        it "returns an empty result set" do
          parsed = JSON.parse(call_service)

          expect(parsed.dig("metadata", "total_results")).to eq(0)
          expect(parsed["data"]).to eq([])
        end
      end

      context "when CRM7 submissions have mixed statuses" do
        before do
          create(:submission, :with_nsm_version,
                 state: "granted",
                 status: "granted",
                 laa_reference: "LAA-GRANTED")
          create(:submission, :with_nsm_version,
                 state: "part_grant",
                 status: "part_grant",
                 laa_reference: "LAA-PART")
          create(:submission, :with_nsm_version,
                 state: "rejected",
                 status: "rejected",
                 laa_reference: "LAA-REJECTED")
        end

        let(:params) { { query: nil, request_type: } }

        it "only returns granted and part-grant CRM7 submissions" do
          parsed = JSON.parse(call_service)

          expect(parsed.dig("metadata", "total_results")).to eq(2)
          expect(parsed.fetch("data").pluck("laa_reference"))
            .to match_array(%w[LAA-GRANTED LAA-PART])
        end
      end
    end

    describe ".call" do
      subject(:class_call) { described_class.call(params, :caseworker) }

      let!(:payment_request) { create(:payment_request, :non_standard_magistrate) }
      let(:params) do
        {
          query: payment_request.payable_claim.laa_reference,
          request_type: payment_request.request_type,
        }
      end

      it "delegates to the instance call" do
        parsed = JSON.parse(class_call)

        expect(parsed.dig("metadata", "total_results")).to eq(1)
      end
    end
  end

  describe PaymentRequests::LinkSubmissionPayments::PaymentRequestsSearch do
    subject(:search) { described_class.new(search_params, :caseworker) }

    let(:request_type) { "non_standard_magistrate" }

    describe "#call" do
      context "with a multi-token query" do
        before do
          create(
            :nsm_claim,
            laa_reference: "LAA-TOKEN",
            ufn: "120223/001",
            solicitor_office_code: "1A123B",
            client_last_name: "smith",
          )
        end

        let(:search_params) { { query: "LAA-TOKEN 120223/001 1A123B Smith", request_type: } }

        it "applies all classifiers" do
          parsed = JSON.parse(search.call)
          expect(parsed.dig("metadata", "total_results")).to eq(1)
        end
      end

      context "with only a client name" do
        before do
          create(:nsm_claim, client_last_name: "carter")
        end

        let(:search_params) { { query: "carter", request_type: } }

        it "skips the laa_reference filter" do
          parsed = JSON.parse(search.call)
          expect(parsed.dig("metadata", "total_results")).to eq(1)
        end
      end

      context "when request_type scopes the claim class" do
        before do
          create(:nsm_claim, laa_reference: "LAA-NSM")
          create(:assigned_counsel_claim, laa_reference: "LAA-AC")
        end

        let(:search_params) { { request_type: "assigned_counsel" } }

        it "returns only assigned counsel claims" do
          parsed = JSON.parse(search.call)

          expect(parsed.dig("metadata", "total_results")).to eq(1)
          expect(parsed.fetch("data").map { _1.fetch("laa_reference") }).to eq(%w[LAA-AC])
        end
      end
    end

    describe "#results?" do
      context "with matching claims" do
        before do
          create(:nsm_claim, laa_reference: "LAA-FINDME")
        end

        let(:search_params) { { query: "LAA-FINDME", request_type: } }

        it "returns true after call" do
          search.call
          expect(search.results?).to be(true)
        end
      end

      context "without matches" do
        let(:search_params) { { query: "LAA-MISSING", request_type: } }

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
          expect(search.send(:sort_clause)).to eq("LOWER(payable_claims.laa_reference) desc")
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

  describe PaymentRequests::LinkSubmissionPayments::Crm7Search do
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
          expect(parsed["data"]).to eq(%w[LAA-CRM7001])
        end

        it "limits the submissions search to granted statuses" do
          allow(Submissions::SearchService).to receive(:new)
            .with(hash_including(status_with_assignment: %w[part_grant granted]), :caseworker)
            .and_return(search_service)

          service.call

          expect(Submissions::SearchService).to have_received(:new)
            .with(hash_including(status_with_assignment: %w[part_grant granted]), :caseworker)
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
end
