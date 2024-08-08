require "rails_helper"

describe "check_autogrants:retrieve_all", type: :task do
  let(:valid_submissions) { create_list(:submission, 2, :with_pa_version, events: [build(:event, :new_version), build(:event, :auto_decision)], application_state: "auto_grant") }
  let(:faulty_submissions) { create_list(:submission, 2, :with_pa_version, events: [build(:event, :new_version)], application_state: "auto_grant") }

  before do
    valid_submissions
    faulty_submissions
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    Rake::Task["check_autogrants:retrieve_all"].reenable
  end

  it "prints out the correct submission ids" do
    expected_output = faulty_submissions.sort_by(&:updated_at).map(&:id).join(",")
    expect { Rake::Task["check_autogrants:retrieve_all"].execute }.to output(expected_output).to_stdout
  end
end
