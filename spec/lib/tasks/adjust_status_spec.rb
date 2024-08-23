require "rails_helper"

describe "adjust:status", type: :task do
  let(:notifier) { instance_double(NotifySubscriber, perform: true) }
  let(:submission) { create(:submission, state: "granted") }
  let(:subscriber) { create(:subscriber, subscriber_type: "caseworker") }
  let(:args) { [submission.id, "rejected"] }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    allow(NotifySubscriber).to receive(:new).and_return(notifier)
    subscriber
    Rake::Task["adjust:status"].invoke(*args)
  end

  after do
    Rake::Task["adjust:status"].reenable
  end

  it "updates the status" do
    expect(submission.reload.state).to eq "rejected"
  end

  it "does not notify anyone by default" do
    expect(notifier).not_to have_received(:perform)
  end

  context "when a different role to notify is specified" do
    let(:args) { [submission.id, "rejected", "provider"] }

    it "does not notify the subscriber" do
      expect(notifier).not_to have_received(:perform)
    end
  end

  context "when the same role to notify is specified" do
    let(:args) { [submission.id, "rejected", "caseworker"] }

    it "notifies the subscriber" do
      expect(notifier).to have_received(:perform).with(subscriber.id, submission.id)
    end
  end
end
