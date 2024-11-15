require "rails_helper"

RSpec.describe "Submission search" do
  let(:search_endpoint) { "/v1/submissions/searches" }

  context "with caseworker app" do
    before do
      allow(Tokens::VerificationService)
        .to receive(:call)
        .and_return(valid: true, role: :caseworker)
    end

    it "returns 201 when successful" do
      post search_endpoint, params: { application_type: "crm4" }
      expect(response).to have_http_status(:created)
    end

    it "returns 422 when unsuccessful" do
      allow(Search).to receive(:where).and_raise(StandardError, "Some error output")
      post search_endpoint, params: { application_type: "crm4" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include(message: "AppStore search query raised Some error output")
    end

    context "when paginating" do
      before do
        create_list(:submission, 2, :with_pa_version, defendant_name: "Joe Bloggs")

        # This travel_to is used to test that "raw data" and [view] data are sync'd by page and order.
        travel_to(1.day.ago) do
          create(:submission, :with_pa_version, defendant_name: "Fred Yankowitz")
          create(:submission, :with_pa_version, defendant_name: "Fred Zeigler")
        end

        create(:submission, :with_pa_version, defendant_name: "Fred Arbor")
        create(:submission, :with_pa_version, defendant_name: "Fred Bloggs")
        create(:submission, :with_nsm_version, application_type: "crm7")
      end

      it "returns an offset of submissions based on pagination" do
        sort_by = "client_name"
        sort_direction = "asc"

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "1",
          application_type: "crm4",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].pluck("client_name")).to match(["Fred Arbor", "Fred Bloggs"])

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "2",
          application_type: "crm4",
          sort_by:,
          sort_direction:,
        }

        expect(response.parsed_body["data"].pluck("client_name")).to match(["Fred Yankowitz", "Fred Zeigler"])
      end

      it "returns metadata about the result set" do
        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "1",
          application_type: "crm4",
        }

        expect(response.parsed_body["metadata"]["total_results"]).to be 4
        expect(response.parsed_body["metadata"]["page"]).to be 1
        expect(response.parsed_body["metadata"]["per_page"]).to be 2
      end

      it "returns raw data result matching the page and order of the data result" do
        sort_by = "client_name"
        sort_direction = "asc"

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "1",
          application_type: "crm4",
          sort_by:,
          sort_direction:,
        }

        client_names = response.parsed_body["raw_data"].each_with_object([]) do |raw, arr|
          arr << "#{raw.dig('application', 'defendant', 'first_name')} #{raw.dig('application', 'defendant', 'last_name')}"
        end

        expect(client_names).to match(["Fred Arbor", "Fred Bloggs"])

        post search_endpoint, params: {
          query: "Fred",
          per_page: "2",
          page: "2",
          application_type: "crm4",
          sort_by:,
          sort_direction:,
        }

        client_names = response.parsed_body["raw_data"].each_with_object([]) do |raw, arr|
          arr << "#{raw.dig('application', 'defendant', 'first_name')} #{raw.dig('application', 'defendant', 'last_name')}"
        end

        expect(client_names).to match(["Fred Yankowitz", "Fred Zeigler"])
      end
    end

    context "with submitted date filter" do
      before do
        travel_to(start_date) do
          create_list(:submission, 3, :with_pa_version, defendant_name: "Jim RightOn")
        end

        travel_to(start_date - 1.day) do
          create(:submission, :with_pa_version, defendant_name: "Jim TooOld")
        end

        travel_to(end_date + 1.day) do
          create(:submission, :with_pa_version, defendant_name: "Jim TooYoung")
        end
      end

      let(:start_date) { 4.weeks.ago }
      let(:end_date) { 1.week.ago }

      context "with a date range" do
        let(:submitted_from) { start_date.to_date.iso8601 }
        let(:submitted_to) { end_date.to_date.iso8601 }

        it "brings back only those submitted between the dates" do
          post search_endpoint, params: {
            query: "Jim",
            application_type: "crm4",
            submitted_from:,
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with a date range of the same day" do
        let(:submitted_from) { start_date.to_date.iso8601 }
        let(:submitted_to) { start_date.to_date.iso8601 }

        it "brings back those updated between the beginning of day and end of day" do
          post search_endpoint, params: {
            query: "Jim",
            application_type: "crm4",
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
            application_type: "crm4",
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
            application_type: "crm4",
            submitted_to:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooold/))
        end
      end
    end

    context "with last_updated filter" do
      before do
        create_list(:submission, 3, :with_pa_version, defendant_name: "Jim RightOn", ufn: "111111/111", last_updated_at: start_date)
        create(:submission, :with_pa_version, defendant_name: "Jim TooOld", ufn: "222222/222", last_updated_at: start_date - 1.day)
        create(:submission, :with_pa_version, defendant_name: "Jim TooYoung", ufn: "333333/333", last_updated_at: end_date + 1.day)
      end

      let(:start_date) { 4.weeks.ago }
      let(:end_date) { 1.week.ago }

      context "with a date range" do
        let(:updated_from) { start_date.to_date.iso8601 }
        let(:updated_to) { end_date.to_date.iso8601 }

        it "brings back only those updated between the dates" do
          post search_endpoint, params: {
            query: "Jim",
            application_type: "crm4",
            updated_from:,
            updated_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with a date range of the same day" do
        let(:updated_from) { start_date.to_date.iso8601 }
        let(:updated_to) { start_date.to_date.iso8601 }

        it "brings back those updated between the beginning of day and end of day" do
          post search_endpoint, params: {
            query: "Jim",
            application_type: "crm4",
            updated_from:,
            updated_to:,
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with an endless date range" do
        let(:updated_from) { start_date.to_date.iso8601 }

        it "brings back only those last updated after the from date" do
          post search_endpoint, params: {
            query: "Jim",
            application_type: "crm4",
            updated_from:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooyoung/))
        end
      end

      context "with a beginless date range" do
        let(:updated_to) { end_date.to_date.iso8601 }

        it "brings back only those last updated before the to date" do
          post search_endpoint, params: {
            query: "Jim",
            application_type: "crm4",
            updated_to:,
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooold/))
        end
      end
    end

    context "with status_with_assignment filter" do
      before do
        create(:submission, :with_pa_version, laa_reference: "LAA-AAAAA1", state: "auto_grant")
        create(:submission, :with_pa_version, laa_reference: "LAA-AAAAA2", state: "auto_grant")
        create(:submission, :with_pa_version, laa_reference: "LAA-BBBBBB", state: "part_grant")
        create(:submission, :with_pa_version, laa_reference: "LAA-CCCCCC", state: "rejected")

        # in_progress pseudo status_with_assignment (submitted with an assignment)
        create(:submission, :with_pa_version, laa_reference: "LAA-DDDDDD", state: "submitted", assigned_user_id: "123")

        # not_assigned pseudo status_with_assignment (submitted without an assignment)
        create(:submission, :with_pa_version, laa_reference: "LAA-EEEEEE", state: "submitted", assigned_user_id: nil)
      end

      it "brings back only those with a matching status_with_assignment" do
        post search_endpoint, params: {
          application_type: "crm4",
          status_with_assignment: "auto_grant",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to contain_exactly("LAA-AAAAA1", "LAA-AAAAA2")

        post search_endpoint, params: {
          application_type: "crm4",
          status_with_assignment: "part_grant",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to contain_exactly("LAA-BBBBBB")

        post search_endpoint, params: {
          application_type: "crm4",
          status_with_assignment: "rejected",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to contain_exactly("LAA-CCCCCC")
      end

      it "can handle a status array" do
        post search_endpoint, params: {
          application_type: "crm4",
          status_with_assignment: %w[part_grant rejected],
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to contain_exactly("LAA-BBBBBB", "LAA-CCCCCC")
      end

      it "brings back only those with a matching psuedo status_with_assignment" do
        post search_endpoint, params: {
          application_type: "crm4",
          status_with_assignment: "in_progress",
        }

        expect(response.parsed_body["data"].size).to be 1
        expect(response.parsed_body["data"].pluck("laa_reference")).to all(include("LAA-DDDDDD"))

        post search_endpoint, params: {
          application_type: "crm4",
          status_with_assignment: "not_assigned",
        }

        expect(response.parsed_body["data"].size).to be 1
        expect(response.parsed_body["data"].pluck("laa_reference")).to all(include("LAA-EEEEEE"))
      end
    end

    context "with caseworker filter" do
      before do
        create(:submission,
               :with_pa_version,
               ufn: "111111/111",
               events: [build(:event, :new_version), build(:event, :assignment, primary_user_id: "primary-user-id-1")])

        create(:submission,
               :with_pa_version,
               ufn: "222222/222",
               events: [build(:event, :new_version),
                        build(:event, :assignment, primary_user_id: "primary-user-id-1"),
                        build(:event, :unassignment, primary_user_id: "primary-user-id-1"),
                        build(:event, :assignment, primary_user_id: "primary-user-id-2")])

        create(:submission,
               :with_pa_version,
               ufn: "333333/333",
               events: [build(:event, :new_version), build(:event, :assignment, primary_user_id: "primary-user-id-2")])
      end

      it "brings back only those with a matching caseworker id" do
        post search_endpoint, params: {
          application_type: "crm4",
          caseworker_id: "primary-user-id-1",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("search_fields")).to all(match("111111/111|222222/222"))
      end
    end

    context "with current caseworker filter" do
      before do
        create(:submission,
               :with_pa_version,
               ufn: "111111/111",
               assigned_user_id: "123-456",
               unassigned_user_ids: [])

        create(:submission,
               :with_pa_version,
               ufn: "222222/222",
               assigned_user_id: "789-789",
               unassigned_user_ids: [])

        create(:submission,
               :with_pa_version,
               ufn: "333333/333",
               assigned_user_id: nil,
               unassigned_user_ids: %w[123-456])
      end

      it "brings back only those with a matching caseworker id" do
        post search_endpoint, params: {
          application_type: "crm4",
          current_caseworker_id: "123-456",
        }

        expect(response.parsed_body["raw_data"].size).to eq 1
        expect(response.parsed_body["raw_data"].pluck("application").pluck("ufn")).to eq(["111111/111"])
      end
    end

    context "with account number filter" do
      before do
        create(:submission,
               :with_pa_version,
               ufn: "111111/111",
               account_number: "ABC123")

        create(:submission,
               :with_pa_version,
               ufn: "222222/222",
               account_number: nil)

        create(:submission,
               :with_pa_version,
               ufn: "333333/333",
               account_number: "DEF456")
      end

      it "brings back only those with a matching account number id" do
        post search_endpoint, params: {
          application_type: "crm4",
          account_number: "ABC123",
        }

        expect(response.parsed_body["raw_data"].size).to eq 1
        expect(response.parsed_body["raw_data"].pluck("application").pluck("ufn")).to eq(["111111/111"])
      end
    end

    context "with id_to_exclude filter" do
      let(:excluded_id) { SecureRandom.uuid }

      before do
        create(:submission,
               :with_pa_version,
               id: excluded_id,
               ufn: "111111/111")

        create(:submission,
               :with_pa_version,
               id: SecureRandom.uuid,
               ufn: "222222/222")
      end

      it "brings back only those that do not" do
        post search_endpoint, params: {
          application_type: "crm4",
          id_to_exclude: excluded_id,
        }

        expect(response.parsed_body["raw_data"].size).to eq 1
        expect(response.parsed_body["raw_data"].pluck("application").pluck("ufn")).to eq(["222222/222"])
      end
    end

    context "with defendant name query for PA" do
      before do
        create(:submission, :with_pa_version,
               defendant_name: "Billy Bob")

        create(:submission, :with_pa_version,
               defendant_name: "Bob Billy")

        create(:submission, :with_pa_version,
               defendant_name: "Fred Bloggs")
      end

      it "returns those with matching first or last name from single defendant object" do
        post search_endpoint, params: {
          application_type: "crm4",
          query: "Billy",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("client_name")).to contain_exactly("Billy Bob", "Bob Billy")
      end
    end

    context "with high_value query for NSM" do
      before do
        create(:submission, :with_nsm_version,
               high_value: true,
               laa_reference: "LAA-AAAAA1")

        create(:submission, :with_nsm_version,
               high_value: true,
               laa_reference: "LAA-AAAAA2")

        create(:submission, :with_nsm_version,
               high_value: false,
               laa_reference: "LAA-AAAAA3")
      end

      it "returns those with has high_value" do
        post search_endpoint, params: {
          application_type: "crm7",
          high_value: true,
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("laa_reference")).to contain_exactly("LAA-AAAAA1", "LAA-AAAAA2")
      end
    end

    context "with defendant name query for NSM with single defendant" do
      before do
        create(:submission, :with_nsm_version,
               defendant_name: "Billy Bob")

        create(:submission, :with_nsm_version,
               defendant_name: "Bob Billy")

        create(:submission, :with_nsm_version,
               defendant_name: "Fred Bloggs")
      end

      it "returns those with matching first or last name from single defendant object" do
        post search_endpoint, params: {
          application_type: "crm7",
          query: "Billy",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("client_name")).to contain_exactly("Billy Bob", "Bob Billy")
      end
    end

    context "with defendant name query for NSM with multiple defendants" do
      before do
        create(:submission, :with_nsm_version,
               defendant_name: "Billy Bob",
               additional_defendant_names: ["Fred Bob"])

        create(:submission, :with_nsm_version,
               defendant_name: "Fred Bloggs",
               additional_defendant_names: ["John Simpson"])
      end

      it "returns those with matching first or last name from any defendant element" do
        post search_endpoint, params: {
          application_type: "crm7",
          query: "Fred",
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("client_name")).to contain_exactly("Billy Bob", "Fred Bloggs")

        post search_endpoint, params: {
          application_type: "crm7",
          query: "Simpson",
        }

        expect(response.parsed_body["data"].size).to be 1
        expect(response.parsed_body["data"].pluck("client_name")).to contain_exactly("Fred Bloggs")
      end
    end

    context "when sorting" do
      before do
        # create in order that will not return succcess without sorting
        travel_to(2.days.ago) do
          create(:submission, :with_pa_version,
                 application_risk: "high",
                 laa_reference: "LAA-BBBBBB",
                 firm_name: "Aardvark & Co",
                 defendant_name: "Billy Bob",
                 state: "auto_grant")
        end

        travel_to(1.day.ago) do
          create(:submission, :with_pa_version,
                 application_risk: "medium",
                 laa_reference: "LAA-CCCCCC",
                 firm_name: "Bob & Sons",
                 defendant_name: "Dilly Dodger",
                 state: "rejected")
        end

        travel_to(3.days.ago) do
          create(:submission, :with_pa_version,
                 application_risk: "low",
                 laa_reference: "LAA-AAAAAA",
                 firm_name: "Xena & Daughters",
                 defendant_name: "Zach Zeigler",
                 state: "granted")
        end
      end

      it "defaults to sorting by last_updated, most recent first" do
        post search_endpoint, params: {
          application_type: "crm4",
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
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by laa_reference descending" do
        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "descending",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "can be sorted by laa_reference case-insensitively" do
        create(:submission, :with_pa_version,
               laa_reference: "LAA-bbbbbb")

        post search_endpoint, params: {
          sort_by: "laa_reference",
          sort_direction: "ascending",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-bbbbbb LAA-CCCCCC]).or match(%w[LAA-AAAAAA LAA-bbbbbb LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by firm_name ascending" do
        post search_endpoint, params: {
          sort_by: "firm_name",
          sort_direction: "asc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Aardvark & Co", "Bob & Sons", "Xena & Daughters"])
      end

      it "can be sorted by firm_name descending" do
        post search_endpoint, params: {
          sort_by: "firm_name",
          sort_direction: "desc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Xena & Daughters", "Bob & Sons", "Aardvark & Co"])
      end

      it "can be sorted by firm_name case-insensitively" do
        create(:submission, :with_pa_version,
               firm_name: "aardvark & co")

        post search_endpoint, params: {
          sort_by: "firm_name",
          sort_direction: "ascending",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("firm_name")).to match(["Aardvark & Co", "aardvark & co", "Bob & Sons", "Xena & Daughters"]).or match(["aardvark & co", "Aardvark & Co", "Bob & Sons", "Xena & Daughters"])
      end

      it "can be sorted by defendant_name ascending" do
        post search_endpoint, params: {
          sort_by: "client_name",
          sort_direction: "asc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("client_name")).to match(["Billy Bob", "Dilly Dodger", "Zach Zeigler"])
      end

      it "can be sorted by defendant_name descending" do
        post search_endpoint, params: {
          sort_by: "client_name",
          sort_direction: "desc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("client_name")).to match(["Zach Zeigler", "Dilly Dodger", "Billy Bob"])
      end

      it "can be sorted by defendant_name case-insensitively" do
        create(:submission, :with_pa_version,
               defendant_name: "billy bob")

        post search_endpoint, params: {
          sort_by: "client_name",
          sort_direction: "asc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("client_name")).to match(["Billy Bob", "billy bob", "Dilly Dodger", "Zach Zeigler"]).or match(["billy bob", "Billy Bob", "Dilly Dodger", "Zach Zeigler"])
      end

      it "can be sorted by status_with_assignment ascending" do
        post search_endpoint, params: {
          sort_by: "status_with_assignment",
          sort_direction: "asc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("status_with_assignment")).to match(%w[auto_grant granted rejected])
      end

      it "can be sorted by status_with_assignment descending" do
        post search_endpoint, params: {
          sort_by: "status_with_assignment",
          sort_direction: "desc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("status_with_assignment")).to match(%w[rejected granted auto_grant])
      end

      it "can be sorted by last_updated ascending" do
        post search_endpoint, params: {
          sort_by: "last_updated",
          sort_direction: "asc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-AAAAAA LAA-BBBBBB LAA-CCCCCC])
      end

      it "can be sorted by last_updated descending" do
        post search_endpoint, params: {
          sort_by: "last_updated",
          sort_direction: "desc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end

      it "can be sorted by risk_level descending" do
        post search_endpoint, params: {
          sort_by: "risk_level",
          sort_direction: "desc",
          application_type: "crm4",
        }

        expect(response.parsed_body["data"].pluck("laa_reference")).to match(%w[LAA-BBBBBB LAA-CCCCCC LAA-AAAAAA])
      end

      it "sorts raw data to match the order of data" do
        post search_endpoint, params: {
          sort_by: "last_updated",
          sort_direction: "desc",
          application_type: "crm4",
        }

        laa_references = response.parsed_body["raw_data"].each_with_object([]) do |raw, arr|
          arr << raw.dig("application", "laa_reference")
        end

        expect(laa_references).to match(%w[LAA-CCCCCC LAA-BBBBBB LAA-AAAAAA])
      end
    end

    context "when searching for queries that may be invalid" do
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
