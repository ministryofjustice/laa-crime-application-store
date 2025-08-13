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
      post search_endpoint, params: { payable_type: "nsm_claim" }
      expect(response).to have_http_status(:created)
    end

    it "returns 422 when unsuccessful" do
      allow(PaymentRequest).to receive(:where).and_raise(StandardError, "Some error output")
      post search_endpoint, params: { payable_type: "nsm_claim" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include(message: "Payment Request search query raised Some error output")
    end

    context "when paginating" do
      before do
        create_list(:payment_request, 2, :non_standard_mag, client_last_name: "Rogers")
        # This travel_to is used to test that "raw data" and [view] data are sync'd by page and order.
        travel_to(1.day.ago) do
          create(:payment_request, :non_standard_mag)
          create(:payment_request, :non_standard_mag)
        end

        create(:payment_request, :non_standard_mag)
        create(:payment_request, :non_standard_mag, client_last_name: "Fred Bloggs")
        create(:payment_request, :assigned_counsel_claim)
      end

      it "returns an offset of submissions based on pagination" do
        sort_by = "client_last_name"
        sort_direction = "asc"

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "1",
          application_type: "nsm_claim",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].pluck("client_last_name")).to match(["Fred Arbor", "Fred Bloggs"])

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "2",
          payable_type: "nsm_claim",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].pluck("client_last_name")).to match(["Fred Yankowitz", "Fred Zeigler"])
      end

      it "returns metadata about the result set" do
        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "1",
          payable_type: "nsm_claim",
        }

        expect(response.parsed_body["metadata"]["total_results"]).to be 4
        expect(response.parsed_body["metadata"]["page"]).to be 1
        expect(response.parsed_body["metadata"]["per_page"]).to be 2
      end

      it "returns raw data result matching the page and order of the data result" do
        sort_by = "client_last_name"
        sort_direction = "asc"

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "1",
          payable_type: "nsm_claim",
          sort_by:,
          sort_direction:,
        }

        client_names = response.parsed_body["raw_data"].each_with_object([]) do |raw, arr|
          arr << "#{raw.dig('payment_request', 'client_last_name')} #{raw.dig('payment_request', 'client_last_name')}"
        end

        expect(client_names).to match(["Arbor", "Bloggs"])

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "2",
          payable_type: "nsm_claim",
          sort_by:,
          sort_direction:,
        }

        client_names = response.parsed_body["raw_data"].each_with_object([]) do |raw, arr|
          arr << "#{raw.dig('payment_request', 'client_last_name')} #{raw.dig('payment_request', 'client_last_name')}"
        end

        expect(client_names).to match(["Yankowitz", "Zeigler"])
      end
    end

    context "with submitted_at filter" do
      before do
        travel_to(start_date) do
          create_list(:payment_request, 3, :non_standard_mag, client_last_name: "RightOn")
        end

        travel_to(start_date - 1.day) do
          create(:payment_request, :non_standard_mag, client_last_name: "Jones")
        end

        travel_to(end_date + 1.day) do
          create(:payment_request, :non_standard_mag, client_last_name:  "TooYoung")
        end
      end

      let(:start_date) { 4.weeks.ago }
      let(:end_date) { 1.week.ago }

      context "with a date range" do
        let(:submitted_from) { start_date.to_date.iso8601 }
        let(:submitted_to) { end_date.to_date.iso8601 }

        it "brings back only those submitted between the dates" do
          post search_endpoint, params: {
            query: "Jones",
            payable_type: "NsmClaim",
            submitted_from:,
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 1
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with a date range of the same day" do
        let(:submitted_from) { start_date.to_date.iso8601 }
        let(:submitted_to) { start_date.to_date.iso8601 }

        it "brings back those updated between the beginning of day and end of day" do
          post search_endpoint, params: {
            query: "Jim",
            payable_type: "nsm_claim",
            submitted_from:,
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with an endless date range" do
        let(:submitted_from) { start_date.to_date.iso8601 }

        it "brings back only those submitted after the from date" do
          post search_endpoint, params: {
            query: "Jim",
            payable_type: "nsm_claim",
            submitted_from:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooyoung/))
        end
      end

      context "with a beginless date range" do
        let(:submitted_to) { end_date.to_date.iso8601 }

        it "brings back only those submitted before the to date" do
          post search_endpoint, params: {
            query: "Jim",
            payable_type: "nsm_claim",
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooold/))
        end
      end
    end

    context "with received_at filter" do
      before do
        create_list(:payment_request, 3, :non_standard_mag, client_last_name: "RightOn", date_claim_received: start_date)
        create(:payment_request, :non_standard_mag, client_last_name: "TooOld", date_claim_received: start_date - 1.day)
        create(:payment_request, :non_standard_mag, client_last_name: "TooYoung", date_claim_received: end_date + 1.day)
      end

      let(:start_date) { 4.weeks.ago }
      let(:end_date) { 1.week.ago }

      context "with a date range" do
        let(:received_from) { start_date.to_date.iso8601 }
        let(:received_to) { end_date.to_date.iso8601 }

        it "brings back only those updated between the dates" do
          post search_endpoint, params: {
            query: "Jim",
            payable_type: "nsm_claim",
            received_from:,
            received_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with a date range of the same day" do
        let(:received_from) { start_date.to_date.iso8601 }
        let(:received_to) { start_date.to_date.iso8601 }

        it "brings back those updated between the beginning of day and end of day" do
          post search_endpoint, params: {
            query: "Jim",
            payable_type: "nsm_claim",
            received_from:,
            received_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with an endless date range" do
        let(:received_from) { start_date.to_date.iso8601 }

        it "brings back only those last updated after the from date" do
          post search_endpoint, params: {
            query: "Jim",
            payable_type: "nsm_claim",
            received_from:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooyoung/))
        end
      end

      context "with a beginless date range" do
        let(:received_to) { end_date.to_date.iso8601 }

        it "brings back only those last updated before the to date" do
          post search_endpoint, params: {
            query: "Jim",
            payable_type: "nsm_claim",
            received_to:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooold/))
        end
      end
    end

    context "with client_last_name query for PA" do
      before do
        create(:payment_request, :non_standard_mag, client_last_name: "Billy Bob")
        create(:payment_request, :non_standard_mag, client_last_name: "Bob Billy")
        create(:payment_request, :non_standard_mag, client_last_name: "fred Bloggs")
      end

      it "returns those with matching first or last name from single defendant object" do
        post search_endpoint, params: {
          application_type: "nsm_claim",
          query: "Billy",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("client_last_name")).to contain_exactly("Billy Bob", "Bob Billy")
      end
    end

    context "with client_last_name query for assigned_counsel_claim" do
      before do
        create(:payment_request, :assigned_counsel_claim, client_last_name: "Billy Bob")
        create(:payment_request, :assigned_counsel_claim, client_last_name: "Bob Billy")
        create(:payment_request, :assigned_counsel_claim, client_last_name: "fred Bloggs")
      end

      it "returns those with matching first or last name from single defendant object" do
        post search_endpoint, params: {
          application_type: "assigned_counsel_claim]",
          query: "Billy",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("client_last_name")).to contain_exactly("Billy Bob", "Bob Billy")
      end
    end

    context "when sorting" do
      before do
        # create in order that will not return succcess without sorting
        travel_to(2.days.ago) do
          create(:payment_request, :non_standard_mag,
            laa_reference: "LAA-BBBBBB",
            submitted_at: Date.now,
            office_code: "1ab",
            client_last_name: "Billy Bob")
        end

        travel_to(1.day.ago) do
          create(:payment_request, :non_standard_mag,
            laa_reference: "LAA-CCCCCC",
            submitted_at: Date.now,
            office_code: "2ab",
            client_last_name: "Dilly Dodger")
        end

        travel_to(3.days.ago) do
          create(:payment_request, :non_standard_mag,
            laa_reference: "LAA-AAAAAA",
            office_code: "3ab",
            submitted_at: Date.now,
            client_last_name: "Zach Zeigler")
        end
      end

      it "defaults to sorting by last_updated, most recent first" do
        post search_endpoint, params: {
          payable_type: "nsm_claim",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "raises an error when unsortable column supplied" do
        post search_endpoint, params: { sort_by: "foobar" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to include(message: "AppStore search query raised Unsortable column \"foobar\" supplied as sort_by argument")
      end

      it "can be sorted by laa_reference ascending" do
        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "ascending",
          payable_type: "nsm_claim",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by laa_reference descending" do
        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "descending",
          payable_type: "nsm_claim"
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "can be sorted by laa_reference case-insensitively" do
          create(:payment_request, :non_standard_mag,
            laa_reference: "LAA-bbbbbb")

        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "ascending",
          payable_type: "nsm_claim"
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-bbbbbb LAA-CCCCCC]).or match(%w[LAA-AAAAAA LAA-bbbbbb LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by client_last_name ascending" do
        post search_endpoint, params: {
          sort_by: "client_last_name",
          sort_direction: "asc",
          application_type: "nsm_claim",
        }

        expect(response.parsed_body["data"].pluck("client_last_name")).to match(["Aardvark & Co", "Bob & Sons", "Xena & Daughters"])
      end

      it "can be sorted by client_last_name case-insensitively" do
          create(:payment_request, :non_standard_mag,
            client_last_name: "billy bob")

        post search_endpoint, params: {
          sort_by: "client_last_name",
          sort_direction: "asc",
          application_type: "nsm_claim",
        }

        expect(response.parsed_body["data"].pluck("client_last_name")).to match(["Billy Bob", "billy bob", "Dilly Dodger", "Zach Zeigler"]).or match(["billy bob", "Billy Bob", "Dilly Dodger", "Zach Zeigler"])
      end

      it "can be sorted by office_code descending" do
        post search_endpoint, params: {
          sort_by: "office_code",
          sort_direction: "desc",
          application_type: "nsm_claim",
        }

        expect(response.parsed_body["data"].pluck("office_code")).to match(%w[1ab 2ab 3ab])
      end

      it "sorts raw data to match the order of data" do
        post search_endpoint, params: {
          sort_by: "submitted_at",
          sort_direction: "desc"
        }

        laa_references = response.parsed_body["raw_data"].each_with_object([]) do |raw, arr|
          arr << raw.dig("payment_request", "laa_reference")
        end

        expect(laa_references).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end
    end

    xcontext "when searching for queries that may be invalid" do
      before do
        create(:submission,
               :with_pa_version,
               laa_reference: "LAA-AAAAAA",
               defendant_name: "Fred Arbor",
               firm_name: "Aardvark & Co")

        create(:submission,
               :with_pa_version,
               laa_reference: "LAA-BBBBBB",
               defendant_name: "Fred Bloggs",
               firm_name: "Smith & (Partners) Ltd.")

        create(:submission,
               :with_pa_version,
               laa_reference: "LAA-CCC123",
               defendant_name: "Jimmy Buffer",
               firm_name: "Über Legal Co.",
               ufn: "311223/001")

        create(:submission,
               :with_pa_version,
               laa_reference: "LAA-MiXeD1",
               defendant_name: "Test Person",
               firm_name: "Aardvark Smithson",
               ufn: "123456")

        create(:submission,
               :with_pa_version,
               laa_reference: "LAA-PUNC28",
               defendant_name: "James O'Connor-Smith",
               firm_name: "Legal & Law (International) Ltd.")
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
