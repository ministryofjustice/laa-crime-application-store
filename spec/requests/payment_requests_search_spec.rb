require "rails_helper"

RSpec.describe "PaymentRequest search" do
  let(:search_endpoint) { "/v1/payment_requests/searches" }

  context "with caseworker app" do
    before do
      allow(Tokens::VerificationService)
        .to receive(:call)
        .and_return(valid: true, role: :caseworker)
    end

    it "returns 201 when successful" do
      post search_endpoint, params: { claim_type: "NsmClaim" }
      expect(response).to have_http_status(:created)
    end

    it "returns 422 when unsuccessful" do
      allow(PaymentRequest).to receive(:left_outer_joins).and_raise(StandardError, "Some error output")
      post search_endpoint, params: { claim_type: "NsmClaim" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to include(message: "PaymentRequests search query raised Some error output")
    end

    context "when paginating" do
      before do
        create_list(:payment_request, 2,
                    payment_request_claim: build(:nsm_claim, client_last_name: "Andrex"))

        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "Bazoo"))
        create(:payment_request, payment_request_claim: build(:nsm_claim, solicitor_office_code: "1A123C", client_last_name: "Andrex"))

        create(:payment_request, payment_request_claim: build(:nsm_claim, solicitor_office_code: "1A123C", client_last_name: "Bazoo"))
        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "Cushelle"))
        create(:payment_request, :assigned_counsel)
      end

      it "returns an offset of submissions based on pagination" do
        sort_by = "client_last_name"
        sort_direction = "asc"

        post search_endpoint, params: {
          query: "1A123B",
          per_page: "2",
          page: "1",
          request_type: "non_standard_magistrate",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(%w[Andrex Andrex])

        post search_endpoint, params: {
          query: "1A123B",
          per_page: "2",
          page: "2",
          request_type: "non_standard_magistrate",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(%w[Bazoo Cushelle])
      end

      it "returns metadata about the result set" do
        post search_endpoint, params: {
          query: "1A123B",
          per_page: "2",
          page: "1",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["metadata"]["total_results"]).to be 4
        expect(response.parsed_body["metadata"]["page"]).to be 1
        expect(response.parsed_body["metadata"]["per_page"]).to be 2
      end
    end

    context "with submission_id" do
      let(:submission_id) { SecureRandom.uuid }
      let(:another_submission_id) { SecureRandom.uuid }

      before do
        create(:payment_request, payment_request_claim: build(:nsm_claim, submission_id: submission_id))
        create(:payment_request, payment_request_claim: build(:nsm_claim, submission_id: another_submission_id))
      end

      it "brings back only matching submission_id" do
        post search_endpoint, params: { submission_id: }

        expect(response.parsed_body["data"].size).to be 1
      end
    end

    context "with submitted_at filter" do
      before do
        travel_to(start_date) do
          create_list(:payment_request, 3,
                      payment_request_claim: build(:nsm_claim, client_last_name: "RightOn"))
        end

        travel_to(start_date - 1.day) do
          create(:payment_request,
                 payment_request_claim: build(:nsm_claim, client_last_name: "TooOld"))
        end

        travel_to(end_date + 1.day) do
          create(:payment_request,
                 payment_request_claim: build(:nsm_claim, client_last_name: "TooYoung"))
        end
      end

      let(:start_date) { 4.weeks.ago }
      let(:end_date) { 1.week.ago }

      context "with a date range" do
        let(:submitted_from) { start_date.to_date.iso8601 }
        let(:submitted_to) { end_date.to_date.iso8601 }

        it "brings back only those submitted between the dates" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            submitted_from:,
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(include("RightOn"))
        end
      end

      context "with a date range of the same day" do
        let(:submitted_from) { start_date.to_date.iso8601 }
        let(:submitted_to) { start_date.to_date.iso8601 }

        it "brings back those updated between the beginning of day and end of day" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            submitted_from:,
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(include("RightOn"))
        end
      end

      context "with an endless date range" do
        let(:submitted_from) { start_date.to_date.iso8601 }

        it "brings back only those submitted after the from date" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            submitted_from:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(match(/RightOn|TooYoung/))
        end
      end

      context "with a beginless date range" do
        let(:submitted_to) { end_date.to_date.iso8601 }

        it "brings back only those submitted before the to date" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(match(/RightOn|TooOld/))
        end
      end
    end

    context "with received_at filter" do
      before do
        create_list(:payment_request, 3, date_received: start_date, payment_request_claim: build(:nsm_claim, client_last_name: "RightOn"))
        create(:payment_request, date_received: start_date - 1.day, payment_request_claim: build(:nsm_claim, client_last_name: "TooOld"))
        create(:payment_request, date_received: end_date + 1.day, payment_request_claim: build(:nsm_claim, client_last_name: "TooYoung"))
      end

      let(:start_date) { 4.weeks.ago }
      let(:end_date) { 1.week.ago }

      context "with a date range" do
        let(:received_from) { start_date.to_date.iso8601 }
        let(:received_to) { end_date.to_date.iso8601 }

        it "brings back only those updated between the dates" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            received_from:,
            received_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(include("RightOn"))
        end
      end

      context "with a date range of the same day" do
        let(:received_from) { start_date.to_date.iso8601 }
        let(:received_to) { start_date.to_date.iso8601 }

        it "brings back those updated between the beginning of day and end of day" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            received_from:,
            received_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(include("RightOn"))
        end
      end

      context "with an endless date range" do
        let(:received_from) { start_date.to_date.iso8601 }

        it "brings back only those last update, after the from date" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            received_from:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(match(/RightOn|TooYoung/))
        end
      end

      context "with a beginless date range" do
        let(:received_to) { end_date.to_date.iso8601 }

        it "brings back only those last updated before the to date" do
          post search_endpoint, params: {
            query: "1A123B",
            request_type: "non_standard_magistrate",
            received_to:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(match(/RightOn|TooOld/))
        end
      end
    end

    context "with client_last_name query for nsm_claim" do
      before do
        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "Vloggs"))
        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "Bloggs"))
        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "Bloggs"))
        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "Vlikks"))
      end

      it "returns those with similar last name from single defendant object" do
        post search_endpoint, params: {
          request_type: "non_standard_magistrate",
          query: "Bloggs",
        }

        expect(response.parsed_body["data"].size).to be 3
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to contain_exactly("Bloggs", "Bloggs", "Vloggs")
      end
    end

    context "with client_last_name query for assigned_counsel_claim" do
      before do
        create(:payment_request, :assigned_counsel, payment_request_claim: build(:assigned_counsel_claim, client_last_name: "Vloggs"))
        create(:payment_request, :assigned_counsel, payment_request_claim: build(:assigned_counsel_claim, client_last_name: "Bloggs"))
        create(:payment_request, :assigned_counsel, payment_request_claim: build(:assigned_counsel_claim, client_last_name: "Bloggs"))
        create(:payment_request, :assigned_counsel, payment_request_claim: build(:assigned_counsel_claim, client_last_name: "Vlikks"))
      end

      it "returns those with similar first or last name from single defendant object" do
        post search_endpoint, params: {
          request_type: "assigned_counsel",
          query: "Bloggs",
        }

        expect(response.parsed_body["data"].size).to be 3
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to contain_exactly("Bloggs", "Bloggs", "Vloggs")
      end
    end

    context "when sorting" do
      before do
        # create in order that will not return succcess without sorting
        travel_to(2.days.ago) do
          create(:payment_request, submitted_at: Time.zone.now, payment_request_claim: build(:nsm_claim,
                                                                                             laa_reference: "LAA-BBBBBB",
                                                                                             solicitor_office_code: "1ab",
                                                                                             client_last_name: "Bob"))
        end

        travel_to(1.day.ago) do
          create(:payment_request, submitted_at: Time.zone.now, payment_request_claim: build(:nsm_claim,
                                                                                             laa_reference: "LAA-CCCCCC",
                                                                                             solicitor_office_code: "2ab",
                                                                                             client_last_name: "Dodger"))
        end

        travel_to(3.days.ago) do
          create(:payment_request, submitted_at: Time.zone.now, payment_request_claim: build(:nsm_claim,
                                                                                             laa_reference: "LAA-AAAAAA",
                                                                                             solicitor_office_code: "3ab",
                                                                                             client_last_name: "Zeigler"))
        end
      end

      it "defaults to sorting by last_updated, most recent first" do
        post search_endpoint, params: {
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "raises an error when unsortable column supplied" do
        post search_endpoint, params: { sort_by: "foobar" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to include(message: "PaymentRequests search query raised Unsortable column \"foobar\" supplied as sort_by argument")
      end

      it "can be sorted by laa_reference ascending" do
        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "ascending",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by laa_reference descending" do
        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "descending",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "can be sorted by laa_reference case-insensitively" do
        create(:payment_request,
               payment_request_claim: build(:nsm_claim, laa_reference: "LAA-bbbbbb"))

        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "ascending",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-bbbbbb LAA-CCCCCC]).or match(%w[LAA-AAAAAA LAA-bbbbbb LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by client_last_name ascending" do
        post search_endpoint, params: {
          sort_by: "client_last_name",
          sort_direction: "asc",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(%w[Bob Dodger Zeigler])
      end

      it "can be sorted by client_last_name case-insensitively" do
        create(:payment_request,
               payment_request_claim: build(:nsm_claim, client_last_name: "bob"))

        post search_endpoint, params: {
          sort_by: "client_last_name",
          sort_direction: "asc",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(%w[Bob bob Dodger Zeigler]).or match(%w[bob Bob Dodger Zeigler])
      end

      it "can be sorted by office_code descending" do
        post search_endpoint, params: {
          sort_by: "solicitor_office_code",
          sort_direction: "desc",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "solicitor_office_code") }).to match(%w[3ab 2ab 1ab])
      end

      it "can be sorted by submitted_at descending" do
        post search_endpoint, params: {
          sort_by: "submitted_at",
          sort_direction: "desc",
          request_type: "non_standard_magistrate",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "solicitor_office_code") }).to match(%w[2ab 1ab 3ab])
      end
    end

    context "when searching for queries that may be invalid" do
      before do
        create(:payment_request, payment_request_claim: build(:nsm_claim,
                                                              laa_reference: "LAA-AAAAAA",
                                                              client_last_name: "Fred Arbor"))

        create(:payment_request, payment_request_claim: build(:nsm_claim,
                                                              laa_reference: "LAA-BBBBBB",
                                                              client_last_name: "Bloggs"))

        create(:payment_request, payment_request_claim: build(:nsm_claim,
                                                              laa_reference: "LAA-CCC123",
                                                              client_last_name: "Buffer",
                                                              ufn: "311223/001"))

        create(:payment_request, payment_request_claim: build(:nsm_claim,
                                                              laa_reference: "LAA-MiXeD1",
                                                              client_last_name: "Pérson",
                                                              ufn: "311223/002"))

        create(:payment_request, payment_request_claim: build(:nsm_claim,
                                                              laa_reference: "LAA-PUNC28",
                                                              client_last_name: "O'Connor-Smith"))
      end

      it "handles a completely invalid query" do
        post search_endpoint, params: { query: "." }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to match([])
      end

      it "handles mixed case references" do
        post search_endpoint, params: { query: "LAA-MiXeD1" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-MiXeD1])
      end

      it "handles complex names" do
        post search_endpoint, params: { query: "O'Connor-Smith" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to eq(["O'Connor-Smith"])
      end

      it "handles UFNs" do
        post search_endpoint, params: { query: "311223/001" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(%w[Buffer])
      end

      it "handles zero-width spaces" do
        post search_endpoint, params: { query: "LAA-AB\u200BC" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to match([])
      end

      it "handles umlauts and accents" do
        post search_endpoint, params: { query: "Pérson" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(%w[Pérson])
      end
    end
  end
end
