require "rails_helper"

RSpec.describe "CRM457_2154:adds_high_value", type: :task do
  let(:valid_submission) { create(:submission, :with_nsm_version, id: valid_submission_id, application_type: "crm7") }
  let(:valid_submission_id) { SecureRandom.uuid }
  let(:missing_summary_submission_low) { create(:submission, build_scope: [:with_nsm_application_no_cost_summary], id: missing_summary_submission_low_id, application_type: "crm7", application_risk: "low") }
  let(:missing_summary_submission_low_id) { SecureRandom.uuid }
  let(:missing_summary_submission_high) { create(:submission, build_scope: [:with_nsm_application_no_cost_summary], id: missing_summary_submission_high_id, application_type: "crm7", application_risk: "high") }
  let(:missing_summary_submission_high_id) { SecureRandom.uuid }
  let(:missing_high_value_submission_low) { create(:submission, build_scope: [:with_nsm_application_low_gross_cost], id: missing_high_value_submission_low_id, application_type: "crm7") }
  let(:missing_high_value_submission_low_id) { SecureRandom.uuid }
  let(:missing_high_value_submission_high) { create(:submission, build_scope: [:with_nsm_application_high_gross_cost], id: missing_high_value_submission_high_id, application_type: "crm7") }
  let(:missing_high_value_submission_high_id) { SecureRandom.uuid }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    valid_submission
    missing_summary_submission_low
    missing_summary_submission_high
    missing_high_value_submission_low
    missing_high_value_submission_high
  end

  after { Rake::Task["CRM457_2154:adds_high_value"].reenable }

  it "updates invalid submissions to correct high value" do
    output_text = ["Updated version 1 of submission: #{missing_summary_submission_low_id} (high_value: false)",
                   "Updated version 1 of submission: #{missing_summary_submission_high_id} (high_value: true)",
                   "Updated version 1 of submission: #{missing_high_value_submission_low_id} (high_value: false)",
                   "Updated version 1 of submission: #{missing_high_value_submission_high_id} (high_value: true)"]

    expect { Rake::Task["CRM457_2154:adds_high_value"].invoke }.to output(include(*output_text)).to_stdout
  end

  it "does not update valid submissions" do
    output_text = "Updated version 1 of submission: #{valid_submission_id}"

    expect { Rake::Task["CRM457_2154:adds_high_value"].invoke }.not_to output(include(output_text)).to_stdout
  end
end
