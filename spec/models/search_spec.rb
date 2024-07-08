require "rails_helper"

RSpec.describe Search do
  describe "#search_laa_reference" do
    let(:search) { described_class.search(query).pluck(:id) }
    let(:prepare) { build(:submission).tap(&:save) }

    before { prepare }

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

          it "returns the both records" do
            expect(search).to eq(prepare.map(&:id))
          end
        end
      end
    end
  end
end
