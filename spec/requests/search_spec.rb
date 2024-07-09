require "rails_helper"

RSpec.describe "Search" do
  context "with caseworker app" do
    before do
      allow(Tokens::VerificationService)
        .to receive(:call)
        .and_return(valid: true, role: :caseworker)
    end

    it "allow searches" do
      post "/v1/search", params: { query: "whatever", filters: { submission_type: "crm4" } }
      expect(response).to have_http_status(:created)
    end

    context "when paginating" do
      before do
        create_list(:submission, 2, :with_pa_version, defendant_name: "Joe Bloggs")
        create_list(:submission, 2, :with_pa_version, defendant_name: "Fred Bloggs")
        create_list(:submission, 2, :with_pa_version, defendant_name: "Fred Sullivan")
        create_list(:submission, 1, :with_nsm_version, application_type: "crm7")
      end

      it "returns a subset of submissions based on pagination" do
        post "/v1/search", params: {
          query: "Fred",
          per_page: "2",
          page: "0",
          filters: { submission_type: "crm4" },
        }

        expect(response.parsed_body["data"].size).to be 2
      end

      it "returns an offset of submissions based on pagination" do
        post "/v1/search", params: {
          query: "Fred",
          per_page: "2",
          page: "2",
          filters: { submission_type: "crm4" },
        }

        expect(response.parsed_body["data"].pluck("search_fields")).to all(include("sullivan"))
      end

      it "returns metadata about the result set" do
        post "/v1/search", params: {
          query: "Fred",
          per_page: "2",
          page: "0",
          filters: { submission_type: "crm4" },
        }

        expect(response.parsed_body["metadata"]["total_results"]).to be 4
        expect(response.parsed_body["metadata"]["page"]).to be 0
        expect(response.parsed_body["metadata"]["per_page"]).to be 2
      end
    end

    context "with submitted date filter" do
      before do
        travel_to(from_date) do
          create_list(:submission, 3, :with_pa_version, defendant_name: "Jim RightOn")
        end

        travel_to(from_date - 1.day) do
          create(:submission, :with_pa_version, defendant_name: "Jim TooOld")
        end

        travel_to(to_date + 1.day) do
          create(:submission, :with_pa_version, defendant_name: "Jim TooYoung")
        end
      end

      let(:from_date) { 4.weeks.ago.to_date }
      let(:to_date) { 1.week.ago.to_date }

      context "with a date range" do
        let(:submitted_from) { from_date.iso8601 }
        let(:submitted_to) { to_date.iso8601 }

        it "brings back only those submitted between the dates" do
          post "/v1/search", params: {
            query: "Jim",
            filters: { submission_type: "crm4",
                       submitted_from:,
                       submitted_to: },
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with an endless date range" do
        let(:submitted_from) { from_date.iso8601 }

        it "brings back only those submitted after the from date" do
          post "/v1/search", params: {
            query: "Jim",
            filters: { submission_type: "crm4",
                       submitted_from: },
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooyoung/))
        end
      end

      context "with a beginless date range" do
        let(:submitted_to) { to_date.iso8601 }

        it "brings back only those submitted before the to date" do
          post "/v1/search", params: {
            query: "Jim",
            filters: { submission_type: "crm4",
                       submitted_to: },
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooold/))
        end
      end
    end

    context "with date updated filter" do
      before do
        travel_to(a_date) do
          create_list(:submission, 3, :with_pa_version, defendant_name: "Jim RightOn", ufn: "111111/111")
          create(:submission, :with_pa_version, defendant_name: "Jim TooOld", ufn: "222222/222")
          create(:submission, :with_pa_version, defendant_name: "Jim TooYoung", ufn: "333333/333")
        end

        travel_to(from_date) do
          SubmissionVersion.where("application ->> 'ufn' = ?", "111111/111").find_each { |ver| ver.submission.touch }
        end

        travel_to(from_date - 1.day) do
          SubmissionVersion.find_by("application ->> 'ufn' = ?", "222222/222").submission.touch
        end

        travel_to(to_date + 1.day) do
          SubmissionVersion.find_by("application ->> 'ufn' = ?", "333333/333").submission.touch
        end
      end

      let(:a_date) { 2.months.ago.to_date }
      let(:from_date) { 4.weeks.ago.to_date }
      let(:to_date) { 1.week.ago.to_date }

      context "with a date range" do
        let(:updated_from) { from_date.iso8601 }
        let(:updated_to) { to_date.iso8601 }

        it "brings back only those updated between the dates" do
          post "/v1/search", params: {
            query: "Jim",
            filters: { submission_type: "crm4",
                       updated_from:,
                       updated_to: },
          }

          expect(response.parsed_body["data"].size).to be 3
          expect(response.parsed_body["data"].pluck("search_fields")).to all(include("righton"))
        end
      end

      context "with an endless date range" do
        let(:updated_from) { from_date.iso8601 }

        it "brings back only those updated after the from date" do
          post "/v1/search", params: {
            query: "Jim",
            filters: { submission_type: "crm4",
                       updated_from: },
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooyoung/))
        end
      end

      context "with a beginless date range" do
        let(:updated_to) { to_date.iso8601 }

        it "brings back only those updated before the to date" do
          post "/v1/search", params: {
            query: "Jim",
            filters: { submission_type: "crm4",
                       updated_to: },
          }

          expect(response.parsed_body["data"].size).to be 4
          expect(response.parsed_body["data"].pluck("search_fields")).to all(match(/righton|tooold/))
        end
      end
    end

    context "with status filter" do
      before do
        create_list(:submission, 3, :with_pa_version, ufn: "111111/111", application_state: "auto_grant")
        create(:submission, :with_pa_version, ufn: "222222/222", application_state: "part_grant")
        create(:submission, :with_pa_version, ufn: "333333/333", application_state: "rejected")
      end

      it "brings back only those with a matching status" do
        post "/v1/search", params: {
          filters: { submission_type: "crm4",
                     status: "auto_grant" },
        }

        expect(response.parsed_body["data"].size).to be 3
        expect(response.parsed_body["data"].pluck("search_fields")).to all(include("111111/111"))

        post "/v1/search", params: {
          filters: { submission_type: "crm4",
                     status: "part_grant" },
        }

        expect(response.parsed_body["data"].size).to be 1
        expect(response.parsed_body["data"].pluck("search_fields")).to all(include("222222/222"))
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
        post "/v1/search", params: {
          filters: { submission_type: "crm4",
                     caseworker_id: "primary-user-id-1" },
        }

        expect(response.parsed_body["data"].size).to be 2
        expect(response.parsed_body["data"].pluck("search_fields")).to all(match("111111/111|222222/222"))
      end
    end
  end
end
