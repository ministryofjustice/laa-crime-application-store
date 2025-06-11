require "rails_helper"

RSpec.describe "CRM457_2627:send_back_expired", type: :task do
  let(:task_run_at) { DateTime.new(2025, 6, 10) }
  let(:updated_at) { Date.new(2025, 5, 20) }
  let(:submission_id) { SecureRandom.uuid }
  let(:application_type) { 'crm4' }
  let(:state) { 'expired' }

  let(:bank_holiday_list) do
    {
      'england-and-wales': {
        events: [
          { date: '2024-01-01' }
        ]
      }
    }
  end

  let(:submission) do
    travel_to updated_at do
      create(
        :submission,
        state:,
        application_type:,
        updated_at:,
        last_updated_at: updated_at,
        events: [
          {
            "id" => "b294b8fb-5353-40ea-a073-76655c34b0e7",
            "created_at" => "2024-11-10T18:08:24.454Z",
            "event_type" => "new_version",
            "submission_version" => 1,
          },
          {
            "id" => "5e85599a-1eaa-4f2e-8401-845456484544",
            "created_at" => "2024-11-11T18:08:24.454Z",
            "event_type" => "send_back",
            "submission_version" => 1,
          },
          {
            "id" => "3d96c9e5-1e46-4e50-861a-0e7c46ed6a8e",
            "created_at" => "2024-11-12T18:08:24.454Z",
            "event_type" => "expired",
            "submission_version" => 2,
          },
        ],
      )
    end
  end

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    stub_request(:get, 'https://www.gov.uk/bank-holidays.json').to_return(
      status: 200,
      body: bank_holiday_list.to_json,
      headers: { 'Content-type' => 'application/json' }
    )
  end

  before :each do
    submission
    travel_to task_run_at do
      Rake::Task["CRM457_2627:send_back_expired"].invoke
    end
  end

  after :each do
    Rake::Task["CRM457_2627:send_back_expired"].reenable
  end

  describe 'in scope expired submissions' do
    it 'state changed' do
      expect(submission.reload.state).to eq('send_back')
    end
  end

  describe 'out of scope expired submissions' do
    let(:updated_at) {Date.new(2025, 5, 10) }
    it 'state is not changed' do
      expect(submission.reload.state).to eq('expired')
    end
  end

  it 'creates a new version of expired record when sent back' do
    expect(submission.reload.current_version).to eq(2)
  end

  it 'sets resubmission deadline to 10 working days from day task is run' do
    expect(submission.reload.latest_version.application['resubmission_deadline']).to eq("2025-06-24T00:00:00.000Z")
  end

  it 'sets application data and row data to expected' do
    expect(submission.reload.latest_version.application['updated_at']).to eq("2025-06-10T00:00:00.000Z")
    expect(submission.reload.latest_version.application['status']).to eq('send_back')
  end

  it 'has the expected associated event' do
    expected = {
      "created_at" => "2025-06-10T00:00:00.000Z",
      "details" => {},
      "does_not_constitute_update" => false,
      "event_type" => "send_back",
      "public" => false,
      "submission_version" => 2,
      "updated_at" => "2025-06-10T00:00:00.000Z"
    }
    expect(submission.reload.events.last.except("id")).to eq(expected)
  end

  it 'previous event was expired event' do
    expect(submission.reload.events[-2]["event_type"]).to eq('expired')
  end
end
