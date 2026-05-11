require "rails_helper"

RSpec.describe Search do
  describe "view projection" do
    it "exposes the search API column contract" do
      expect(described_class.column_names).to contain_exactly(
        "id",
        "application_version_id",
        "ufn",
        "laa_reference",
        "firm_name",
        "account_number",
        "service_name",
        "high_value",
        "last_state_change",
        "risk_level",
        "client_name",
        "search_fields",
        "unassigned_user_ids",
        "assigned_user_id",
        "date_submitted",
        "last_updated",
        "status_with_assignment",
        "application_type",
        "risk",
      )
      expect(described_class.columns_hash.fetch("high_value").type).to be(:boolean)
    end

    it "projects prior authority fields from the current submission version" do
      created_at = Time.zone.local(2026, 4, 1, 10, 0, 0)
      last_updated_at = Time.zone.local(2026, 4, 2, 11, 0, 0)
      submission = create(
        :submission,
        :with_pa_version,
        application_risk: "high",
        assigned_user_id: "caseworker-id",
        unassigned_user_ids: %w[previous-caseworker-id],
        defendant_name: "Ada Lovelace",
        firm_name: "Analytical Engines LLP",
        account_number: "1A111A",
        ufn: "111111/111",
        laa_reference: "LAA-AAAAA1",
        created_at:,
        last_updated_at:,
      )

      search = described_class.find(submission.id)

      expect(search).to have_attributes(
        application_version_id: submission.latest_version.id,
        ufn: "111111/111",
        laa_reference: "LAA-AAAAA1",
        firm_name: "Analytical Engines LLP",
        account_number: "1A111A",
        service_name: nil,
        high_value: nil,
        risk_level: 3,
        client_name: "Ada Lovelace",
        unassigned_user_ids: %w[previous-caseworker-id],
        assigned_user_id: "caseworker-id",
        date_submitted: created_at,
        last_updated: last_updated_at,
        status_with_assignment: "in_progress",
        application_type: "crm4",
        risk: "high",
      )
    end

    it "projects non-standard magistrates fields from the main defendant" do
      submission = create(
        :submission,
        build_scope: [:with_nsm_application_high_value],
        application_type: "crm7",
        defendant_name: "Grace Hopper",
        additional_defendant_names: ["Margaret Hamilton"],
        firm_name: "Compiler & Co",
        account_number: "2B222B",
        ufn: "222222/222",
        laa_reference: "LAA-BBBBB2",
      )

      search = described_class.find(submission.id)

      expect(search).to have_attributes(
        application_version_id: submission.latest_version.id,
        ufn: "222222/222",
        laa_reference: "LAA-BBBBB2",
        firm_name: "Compiler & Co",
        account_number: "2B222B",
        high_value: true,
        risk_level: 1,
        client_name: "Grace Hopper",
        status_with_assignment: "not_assigned",
        application_type: "crm7",
        risk: "low",
      )
    end
  end

  describe "#where_terms" do
    let(:search) { described_class.where_terms(query).pluck(:id) }
    let(:prepare) { build(:submission).tap(&:save) }

    before { prepare }

    context "when search text is nil" do
      let(:query) { nil }

      it "returns all records" do
        expect(search).to eq([prepare.id])
      end
    end

    context "when search text is LAA reference" do
      let(:query) { "LAA-123456" }

      it "returns the record" do
        expect(search).to eq([prepare.id])
      end
    end

    context "when search text is LAA reference does not match any records" do
      let(:query) { "LAA-121212" }

      it "returns the record" do
        expect(search).to be_empty
      end
    end

    context "when search text is full number part of LAA reference" do
      let(:query) { "123456" }

      it "returns the record" do
        expect(search).to be_empty
      end
    end

    context "when search text is partial number part of LAA reference" do
      let(:query) { "345" }

      it "returns the record" do
        expect(search).to be_empty
      end
    end

    context "when search text is 'laa'" do
      let(:query) { "laa" }

      it "returns the record" do
        expect(search).to be_empty
      end
    end

    context "when search text is full defendant name" do
      let(:query) { "joe bloggs" }

      context "with with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end
    end

    context "when search text is laa-reference and full defendant name" do
      let(:query) { "LAA-123456 joe bloggs" }

      context "with with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end
    end

    context "when partial match on part of defendant name" do
      let(:query) { "joe blog" }

      context "with with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end
    end

    context "when it does not match all parts of defendant name" do
      let(:query) { "bob bloggs" }

      context "with with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version).tap(&:save) }

        it "returns the record" do
          expect(search).to be_empty
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version).tap(&:save) }

        it "returns the record" do
          expect(search).to be_empty
        end
      end
    end

    context "when search text is partial defendant name" do
      let(:query) { "joe" }

      context "with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end
    end

    context "when search text has a leading space" do
      let(:query) { " joe" }

      context "with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version).tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end
    end

    context "when user name is Jason/Jim" do
      let(:query) { "Jason/Jim" }

      context "with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version, defendant_name: "Jason/Jim Read").tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end

        context "with additional partial name matches" do
          let(:prepare) do
            [
              build(:submission, :with_pa_version, defendant_name: "Jason/Jim Read").tap(&:save),
              build(:submission, :with_pa_version, defendant_name: "Jason Write").tap(&:save),
              build(:submission, :with_pa_version, defendant_name: "Jim Type").tap(&:save),
              build(:submission, :with_pa_version, defendant_name: "Jack Burns").tap(&:save),
            ]
          end

          it "only matches when both name parts are present" do
            expect(search).to eq([prepare[0].id])
          end
        end

        context "when searching on the first part of first name only" do
          let(:query) { "Jason" }

          it "returns the record" do
            expect(search).to eq([prepare.id])
          end
        end

        context "when searching on the last part of first name only" do
          let(:query) { "Jim" }

          it "returns the record" do
            expect(search).to eq([prepare.id])
          end
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version, defendant_name: "Jason/Jim Read").tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end
    end

    context "when user last name is Burden-Hall" do
      let(:query) { "Burden-Hall" }

      context "with prior authority application" do
        let(:prepare) { build(:submission, :with_pa_version, defendant_name: "Jack Burden-Hall").tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end

        context "with additional partial name matches" do
          let(:prepare) do
            [
              build(:submission, :with_pa_version, defendant_name: "Jack Burden-Hall").tap(&:save),
              build(:submission, :with_pa_version, defendant_name: "Jim Burden").tap(&:save),
              build(:submission, :with_pa_version, defendant_name: "James Hall").tap(&:save),
              build(:submission, :with_pa_version, defendant_name: "jack Ball").tap(&:save),
            ]
          end

          it "only matches when both name parts are present" do
            expect(search).to eq([prepare[0].id])
          end
        end

        context "when searching on the first part of last name only" do
          let(:query) { "Burden" }

          it "returns the record" do
            expect(search).to eq([prepare.id])
          end
        end

        context "when searching on the last part of last name only" do
          let(:query) { "Hall" }

          it "returns the record" do
            expect(search).to eq([prepare.id])
          end
        end
      end

      context "with non-standard magistrate application" do
        let(:prepare) { build(:submission, :with_nsm_version, defendant_name: "Jack Burden-Hall").tap(&:save) }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end
    end

    context "when firm name is Wonder-1984" do
      let(:query) { "Wonder-1984" }

      let(:prepare) { build(:submission, firm_name: "Wonder-1984").tap(&:save) }

      it "returns the record" do
        expect(search).to eq([prepare.id])
      end

      context "with additional partial name matches" do
        let(:prepare) do
          [
            build(:submission, firm_name: "Wonder-1984").tap(&:save),
            build(:submission, firm_name: "Wonder").tap(&:save),
            build(:submission, firm_name: "Hope-1984").tap(&:save),
            build(:submission, firm_name: "jack Ball").tap(&:save),
          ]
        end

        it "only matches when both name parts are present" do
          expect(search).to eq([prepare[0].id])
        end
      end

      context "when searching on the first part of firm name only" do
        let(:query) { "Wonder" }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end
      end

      context "when searching on the last part of firm name only" do
        let(:query) { "1984" }

        it "does not match as thinks it needs `-1984`" do
          expect(search).to be_empty
        end
      end
    end

    context "when matching on UFN" do
      let(:query) { "010124/001" }

      it "returns the record" do
        expect(search).to eq([prepare.id])
      end

      context "when only first part of the ufn" do
        let(:query) { "010124" }

        it "returns the record" do
          expect(search).to eq([prepare.id])
        end

        context "when it also matches a firm name" do
          let(:prepare) do
            [
              build(:submission, ufn: "010123/002", firm_name: "party 010124").tap(&:save),
              build(:submission, firm_name: "Wonder-1984").tap(&:save),
            ]
          end

          it "returns both records" do
            expect(search.sort).to eq(prepare.map(&:id).sort)
          end
        end
      end
    end
  end
end
