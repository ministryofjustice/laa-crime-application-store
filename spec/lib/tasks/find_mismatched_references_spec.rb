require "rails_helper"

describe "fixes:mismatched_references:find", type: :task do
  let(:valid_reference) { "LAA-123456" }
  let(:invalid_reference) { "LAA-ABCDEF" }
  let(:changed_reference) { "LAA-654321" }
  let(:valid_submission) { create(:submission, :with_pa_version, current_version: 3, laa_reference: valid_reference) }
  let(:invalid_submission) { create(:submission, :with_pa_version, current_version: 3, laa_reference: invalid_reference) }
  let(:additional_invalid_version) { create(:submission_version, laa_reference: changed_reference, version: 2, submission: invalid_submission) }

  before do
    valid_submission
    create(:submission_version, :with_pa_application, version: 2, submission: valid_submission)
    create(:submission_version, :with_pa_application, version: 3, submission: valid_submission)
    invalid_submission
    create(:submission_version, laa_reference: "LAA-654321", version: 2, submission: invalid_submission)
    create(:submission_version, laa_reference: "LAA-654321", version: 2, submission: invalid_submission)
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    Rake::Task["fixes:mismatched_references:find"].reenable
  end

  it "prints out the correct information" do
    invalid_versions = invalid_submission.ordered_submission_versions.pluck(Arel.sql("application -> 'laa_reference'")).uniq.join(",")
    expected_output = "Submission ID: #{invalid_submission.id} Original Ref: #{invalid_reference} All References: #{invalid_versions}\n"
    expect { Rake::Task["fixes:mismatched_references:find"].execute }.to output(expected_output).to_stdout
  end
end
