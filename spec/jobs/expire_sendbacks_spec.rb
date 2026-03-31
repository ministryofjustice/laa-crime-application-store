require "rails_helper"

RSpec.describe ExpireSendbacks do
  describe "#perform" do
    let(:submission) { create(:submission, state:) }

    before do
      submission.latest_version.update!(application: { resubmission_deadline: deadline })
      described_class.new.perform
    end

    context "when an submission is overdue expiry" do
      let(:state) { "sent_back" }
      let(:deadline) { 1.day.ago }

      it "marks as expired" do
        expect(submission.reload.state).to eq "expired"
      end

      it "creates an event" do
        expect(submission.reload.events.first).to include("event_type" => "expiry")
      end
    end

    context "when an submission is not sent back" do
      let(:state) { "submitted" }
      let(:deadline) { 1.day.ago }

      it "does not mark as expired" do
        expect(submission.reload.state).not_to eq "expired"
      end
    end

    context "when an submission is only recently sent back" do
      let(:state) { "sent_back" }
      let(:deadline) { 1.day.from_now }

      it "does not mark as expired" do
        expect(submission.reload.state).not_to eq "expired"
      end
    end
  end
end
