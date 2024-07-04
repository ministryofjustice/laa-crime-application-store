require "rails_helper"

RSpec.describe Search do
  describe '#search_laa_reference' do
    before { prepare }
    subject { described_class.search(query).pluck(:id) }
    let(:prepare) { build(:submission).tap(&:save) }

    context 'when search text is LAA reference' do
      let(:query) { "LAA-123456" }

      it 'returns the record' do
        expect(subject).to eq([prepare.id])
      end
    end

    context 'when search text is not LAA reference' do
      let(:query) { "LAA-121212" }

      it 'returns the record' do
        expect(subject).to be_empty
      end
    end

    context 'when search text is full number part of LAA reference' do
      let(:query) { "123456" }

      it 'returns the record' do
        expect(subject).to be_empty
      end
    end

    context 'when search text is partial number part of LAA reference' do
      let(:query) { "345" }

      it 'returns the record' do
        expect(subject).to be_empty
      end
    end

    context "when search text is 'laa'" do
      let(:query) { "laa" }

      it 'returns the record' do
        debugger
        expect(subject).to be_empty
      end
    end
  end
end