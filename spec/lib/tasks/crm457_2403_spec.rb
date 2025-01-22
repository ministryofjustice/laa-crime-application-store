require "rails_helper"

RSpec.describe "CRM457_2403:backfill_last_updated_at", type: :task do
  let(:pre_ssot_date) { Date.new(2024, 11, 17) }
  let(:post_ssot_date) { Date.new(2024, 11, 18) }
  let(:pre_ssot_submission_id) { SecureRandom.uuid }
  let(:pre_ssot_submission) do
    create(
      :submission,
      id: pre_ssot_submission_id,
      state: "provider_updated",
      updated_at: pre_ssot_date,
      last_updated_at: pre_ssot_date,
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
          "event_type" => "new_version",
          "submission_version" => 3,
        },
        {
          "id" => "26165504-7d4b-4eab-b1d6-a465bf110776",
          "created_at" => "2024-11-13T18:08:24.454Z",
          "event_type" => "send_back",
          "submission_version" => 3,
        },
        {
          "id" => "12768821-799b-4e63-af13-d200620ceeb9",
          "created_at" => "2024-11-17T18:08:24.454Z",
          "event_type" => "new_version",
          "submission_version" => 5,
        },
      ],
    )
  end
  let(:crm7_post_ssot_provider_updated_submission_id) { SecureRandom.uuid }
  let(:crm7_post_ssot_provider_updated_submission) do
    create(
      :submission,
      id: crm7_post_ssot_provider_updated_submission_id,
      application_type: "crm7",
      state: "provider_updated",
      updated_at: post_ssot_date,
      last_updated_at: pre_ssot_date,
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
          "event_type" => "new_version",
          "submission_version" => 3,
        },
        {
          "id" => "26165504-7d4b-4eab-b1d6-a465bf110776",
          "created_at" => "2024-11-13T18:08:24.454Z",
          "event_type" => "send_back",
          "submission_version" => 3,
        },
        {
          "id" => "12768821-799b-4e63-af13-d200620ceeb9",
          "created_at" => "2024-11-20T18:08:24.454Z",
          "event_type" => "new_version",
          "submission_version" => 5,
        },
      ],
    )
  end
  let(:crm7_post_ssot_non_provider_updated_submission_id) { SecureRandom.uuid }
  let(:crm7_post_ssot_non_provider_updated_submission) do
    create(
      :submission,
      id: crm7_post_ssot_non_provider_updated_submission_id,
      application_type: "crm7",
      state: "sent_back",
      updated_at: post_ssot_date,
      last_updated_at: pre_ssot_date,
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
          "event_type" => "new_version",
          "submission_version" => 3,
        },
        {
          "id" => "26165504-7d4b-4eab-b1d6-a465bf110776",
          "created_at" => "2024-11-18T18:08:24.454Z",
          "event_type" => "send_back",
          "submission_version" => 3,
        },
      ],
    )
  end
  let(:crm4_post_ssot_provider_updated_submission_id) { SecureRandom.uuid }
  let(:crm4_post_ssot_provider_updated_submission) do
    create(
      :submission,
      id: crm4_post_ssot_provider_updated_submission_id,
      application_type: "crm4",
      state: "provider_updated",
      updated_at: post_ssot_date,
      last_updated_at: pre_ssot_date,
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
          "event_type" => "provider_updated",
          "submission_version" => 3,
        },
        {
          "id" => "26165504-7d4b-4eab-b1d6-a465bf110776",
          "created_at" => "2024-11-18T18:08:24.454Z",
          "event_type" => "send_back",
          "submission_version" => 3,
        },
        {
          "id" => "26165504-7d4b-4eab-b1d6-a465bf110776",
          "created_at" => "2024-11-20T18:08:24.454Z",
          "event_type" => "provider_updated",
          "submission_version" => 5,
        },
      ],
    )
  end
  let(:crm4_post_ssot_non_provider_updated_submission_id) { SecureRandom.uuid }
  let(:crm4_post_ssot_non_provider_updated_submission) do
    create(
      :submission,
      id: crm4_post_ssot_non_provider_updated_submission_id,
      application_type: "crm4",
      state: "sent_back",
      updated_at: post_ssot_date,
      last_updated_at: pre_ssot_date,
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
          "event_type" => "provider_updated",
          "submission_version" => 3,
        },
        {
          "id" => "26165504-7d4b-4eab-b1d6-a465bf110776",
          "created_at" => "2024-11-19T18:08:24.454Z",
          "event_type" => "send_back",
          "submission_version" => 3,
        },
      ],
    )
  end

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    pre_ssot_submission
    crm7_post_ssot_provider_updated_submission
    crm7_post_ssot_non_provider_updated_submission
    crm4_post_ssot_provider_updated_submission
    crm4_post_ssot_non_provider_updated_submission
  end

  after { Rake::Task["CRM457_2403:backfill_last_updated_at"].reenable }

  it "only updates relevant submissions" do
    output_text = [
      "Updated Submission ID: #{crm7_post_ssot_provider_updated_submission_id}'s last_updated_at to 2024-11-20 00:00:00 UTC",
      "Updated Submission ID: #{crm4_post_ssot_provider_updated_submission_id}'s last_updated_at to 2024-11-20 00:00:00 UTC",
    ]

    expect { Rake::Task["CRM457_2403:backfill_last_updated_at"].invoke }.to output(include(*output_text)).to_stdout
  end
end
