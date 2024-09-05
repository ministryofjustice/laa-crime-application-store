require "rails_helper"

describe "fixes:mismatched_references:auto_fix", type: :task do
  let(:valid_reference) { "LAA-123456" }
  let(:invalid_reference) { "LAA-ABCDEF" }
  let(:valid_submission) { create(:submission, :with_pa_version, current_version: 3, laa_reference: valid_reference) }
  let(:invalid_submission) { create(:submission, :with_pa_version, current_version: 3, laa_reference: invalid_reference) }

  before do
    valid_submission
    create(:submission_version, :with_pa_application, version: 2, submission: valid_submission)
    create(:submission_version, :with_pa_application, version: 3, submission: valid_submission)
    invalid_submission
    create(:submission_version, laa_reference: "LAA-654321", version: 2, submission: invalid_submission)
    create(:submission_version, laa_reference: "LAA-654321", version: 3, submission: invalid_submission)
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    Rake::Task["fixes:mismatched_references:auto_fix"].reenable
  end

  it "invalid laa references are corrected" do
    Rake::Task["fixes:mismatched_references:auto_fix"].execute
    valid_versions = valid_submission.ordered_submission_versions.map(&:application)
    fixed_versions = invalid_submission.ordered_submission_versions.map(&:application)
    expect(valid_versions.select { _1["laa_reference"] == valid_reference }.count).to eq(3)
    expect(fixed_versions.select { _1["laa_reference"] == invalid_reference }.count).to eq(3)
  end
end
