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
  end
end
