require "rails_helper"

RSpec.describe "adjust:update_state" do
  before do
    load "spec/lib/tasks/adjust_update_state_data.rb"
  end

  it "Processes as expected" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PERSIST_ADJUSTMENT").and_return("true")
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["adjust:update_state"].invoke

    join_sql = <<~SQL.squish
      join application_version av
        on av.application_id = application_version.application_id
        and av.application ->> 'status' = application_version.application ->> 'status'
        and av.version = application_version.version - 1
    SQL

    expect(SubmissionVersion.joins(:submission).joins(join_sql).pluck(:id)).to match_array(
      %w[
        79d08836-ab0c-4cae-9772-1bae4cd6206f
        592e6d32-c1a8-4d8f-a0a2-58c8649e58b2
        fc9aa56a-b371-4adc-ad0b-e28c19c5980e
        76bb65ac-e185-4ca0-96a3-238d269d0baf
        50e4b5c3-9b20-4344-a141-8cb08516cefa
        ec0d049c-499a-474a-86e5-d45054d6e880
        fc31b11d-5a75-469c-84cc-3fc351db35d2
        81fb918e-ad10-45ae-98c6-1fabf3c3a7c4
      ],
    )
  end
end
