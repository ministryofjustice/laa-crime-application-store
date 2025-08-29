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

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include(message: "PaymentRequests search query raised Some error output")
    end

    context "when paginating" do
      before do
        create_list(:payment_request, 2,
          payment_request_claim: build(:nsm_claim, client_last_name: "Andrex"))

        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "Bazoo"))
        create(:payment_request, payment_request_claim: build(:nsm_claim, office_code: "1A123C", client_last_name: "Andrex"))

        create(:payment_request, payment_request_claim: build(:nsm_claim, office_code: "1A123C", client_last_name: "Bazoo"))
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
          claim_type: "NsmClaim",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(["Andrex", "Andrex"])

        post search_endpoint, params: {
          query: "1A123B",
          per_page: "2",
          page: "2",
          claim_type: "NsmClaim",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(["Bazoo", "Cushelle"])
      end

      it "returns metadata about the result set" do
        post search_endpoint, params: {
          query: "1A123B",
          per_page: "2",
          page: "1",
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["metadata"]["total_results"]).to be 4
        expect(response.parsed_body["metadata"]["page"]).to be 1
        expect(response.parsed_body["metadata"]["per_page"]).to be 2
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
            claim_type: "NsmClaim",
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
            claim_type: "NsmClaim",
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
            claim_type: "NsmClaim",
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
            claim_type: "NsmClaim",
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to all(match(/RightOn|TooOld/))
        end
      end
    end

    context "with received_at filter" do
      before do
        create_list(:payment_request, 3, payment_request_claim: build(:nsm_claim, client_last_name: "RightOn", date_received: start_date))
        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "TooOld", date_received: start_date - 1.day))
        create(:payment_request, payment_request_claim: build(:nsm_claim, client_last_name: "TooYoung", date_received: end_date + 1.day))
      end

      let(:start_date) { 4.weeks.ago }
      let(:end_date) { 1.week.ago }

      context "with a date range" do
        let(:received_from) { start_date.to_date.iso8601 }
        let(:received_to) { end_date.to_date.iso8601 }

        it "brings back only those updated between the dates" do
          post search_endpoint, params: {
            query: "1A123B",
            claim_type: "NsmClaim",
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
            claim_type: "NsmClaim",
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
            claim_type: "NsmClaim",
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
            claim_type: "NsmClaim",
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
      end

      it "returns those with matching last name from single defendant object" do
        post search_endpoint, params: {
          claim_type: "NsmClaim",
          query: "Bloggs",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to contain_exactly("Bloggs", "Bloggs")
      end
    end

    context "with client_last_name query for assigned_counsel_claim" do
      before do
        create(:payment_request, :assigned_counsel, payment_request_claim: build(:assigned_counsel_claim, client_last_name: "Vloggs"))
        create(:payment_request, :assigned_counsel, payment_request_claim: build(:assigned_counsel_claim, client_last_name: "Bloggs"))
        create(:payment_request, :assigned_counsel, payment_request_claim: build(:assigned_counsel_claim, client_last_name: "Bloggs"))
      end


      it "returns those with matching first or last name from single defendant object" do
        post search_endpoint, params: {
          claim_type: "AssignedCounselClaim",
          query: "Bloggs",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to contain_exactly("Bloggs", "Bloggs")
      end
    end

    context "when sorting" do
      before do
        # create in order that will not return succcess without sorting
        travel_to(2.days.ago) do
          create(:payment_request, submitted_at: DateTime.now, payment_request_claim: build(:nsm_claim,
            laa_reference: "LAA-BBBBBB",
            office_code: "1ab",
            client_last_name: "Bob"))
        end

        travel_to(1.day.ago) do
          create(:payment_request, submitted_at: DateTime.now, payment_request_claim: build(:nsm_claim,
            laa_reference: "LAA-CCCCCC",
            office_code: "2ab",
            client_last_name: "Dodger"))
        end

        travel_to(3.days.ago) do
          create(:payment_request, submitted_at: DateTime.now, payment_request_claim: build(:nsm_claim,
            laa_reference: "LAA-AAAAAA",
            office_code: "3ab",
            client_last_name: "Zeigler"))
        end
      end

      it "defaults to sorting by last_updated, most recent first" do
        post search_endpoint, params: {
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "raises an error when unsortable column supplied" do
        post search_endpoint, params: { sort_by: "foobar" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to include(message: "PaymentRequests search query raised Unsortable column \"foobar\" supplied as sort_by argument")
      end

      it "can be sorted by laa_reference ascending" do
        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "ascending",
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by laa_reference descending" do
        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "descending",
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "can be sorted by laa_reference case-insensitively" do
        create(:payment_request,
                payment_request_claim: build(:nsm_claim, laa_reference: "LAA-bbbbbb"))

        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "ascending",
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "laa_reference") }).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-bbbbbb LAA-CCCCCC]).or match(%w[LAA-AAAAAA LAA-bbbbbb LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by client_last_name ascending" do
        post search_endpoint, params: {
          sort_by: "client_last_name",
          sort_direction: "asc",
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(["Bob", "Dodger", "Zeigler"])
      end

      it "can be sorted by client_last_name case-insensitively" do
        create(:payment_request,
          payment_request_claim: build(:nsm_claim, client_last_name: "bob"))

        post search_endpoint, params: {
          sort_by: "client_last_name",
          sort_direction: "asc",
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "client_last_name") }).to match(["Bob", "bob", "Dodger", "Zeigler"]).or match(["bob", "Bob", "Dodger", "Zeigler"])
      end

      it "can be sorted by office_code descending" do
        post search_endpoint, params: {
          sort_by: "office_code",
          sort_direction: "desc",
          claim_type: "NsmClaim",
        }

        expect(response.parsed_body["data"].map { _1.dig("payment_request_claim", "office_code") }).to match(%w[3ab 2ab 1ab])
      end
    end

    xcontext "when searching for queries that may be invalid" do
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
               client_last_name: "Person",
               ufn: "123456"))

        create(:payment_request, payment_request_claim: build(:nsm_claim,
               laa_reference: "LAA-PUNC28",
               client_last_name: "O'Connor-Smith"))

      end

      it "handles a completely invalid query" do
        post search_endpoint, params: { query: "." }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to match([])
      end

      it "ignores unmatched parentheses" do
        post search_endpoint, params: { query: "Fred)" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("client_name")).to match(["Fred Bloggs", "Fred Arbor"])
      end

      it "ignores a real query attempt" do
        post search_endpoint, params: { query: "LAA-AAAAAA)" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-AAAAAA])
      end

      it "handles mixed case references" do
        post search_endpoint, params: { query: "LAA-MiXeD1" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-MiXeD1])
      end

      it "handles complex names" do
        post search_endpoint, params: { query: "O'Connor-Smith" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("client_name")).to eq(["James O'Connor-Smith"])
      end

      it "ignores unescaped ampersands" do
        post search_endpoint, params: { query: "Aardvark & Co" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Aardvark & Co"])
      end

      it "doesn't treat ampersands as tokens" do
        post search_endpoint, params: { query: "Aardvark &" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Aardvark Smithson", "Aardvark & Co"])
      end

      it "handles records with multiple matches that have punctuation" do
        post search_endpoint, params: { query: "Smith" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Legal & Law (International) Ltd.", "Aardvark Smithson", "Smith & (Partners) Ltd."])
      end

      it "handles records that have punctuation and being in the query" do
        post search_endpoint, params: { query: "Smith & (Partners) Ltd." }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Smith & (Partners) Ltd."])
      end

      it "handles UFNs" do
        post search_endpoint, params: { query: "311223/001" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Über Legal Co."])
      end

      it "handles 6 digit strings of numbers that could be UFNs" do
        post search_endpoint, params: { query: "311223" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Über Legal Co."])
      end

      it "does not handle 9 digit strings of numbers that could be UFNs" do
        post search_endpoint, params: { query: "311223001" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to match([])
      end

      it "handles multiple spaces between words" do
        post search_endpoint, params: { query: "Aardvark       &                     Co" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Aardvark & Co"])
      end

      it "handles leading & trailing spaces" do
        post search_endpoint, params: { query: " Aardvark & Co   " }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Aardvark & Co"])
      end

      it "handles zero-width spaces" do
        post search_endpoint, params: { query: "LAA-AB\u200BC" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"]).to match([])
      end

      it "handles emojis" do
        post search_endpoint, params: { query: "Aardvark😊 & Co" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Aardvark & Co"])
      end

      it "handles umlauts and accents" do
        post search_endpoint, params: { query: "Über" }

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Über Legal Co."])
      end
    end
  end
end
