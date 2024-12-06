require "rails_helper"

describe "adjust:status", type: :task do
  let(:submission) { create(:submission, state: "granted") }
  let(:args) { [submission.id, "rejected"] }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["adjust:status"].invoke(*args)
  end

  after do
    Rake::Task["adjust:status"].reenable
  end

  it "updates the status" do
    expect(submission.reload.state).to eq "rejected"
  end
end
