require "factory_bot"

# puts SubmissionVersion.where(application_id: record.id).map { |ver| [ver.application['updated_at'], ver.application_id, ver.version, ver.submission.events.map {|eve| [eve['submission_version'], eve['event_type'], eve['created_at'] ]} ] }.inspect

data = [
  ["14994bfc-95c2-4ddb-94a0-1b84cbc1f7f0", "2024-06-25T12:51:32.494Z", "00061702-ce7b-4dc8-bc6c-ec13cf0ceae2", 2, [[1, "new_version", "2024-06-24T16:15:47.492Z"], [1, "assignment", "2024-06-25T12:48:42.862Z"], [1, "send_back", "2024-06-25T12:51:32.494Z"], [3, "provider_updated", "2024-06-25T15:10:08.417+00:00"], [3, "assignment", "2024-06-26T12:29:08.640Z"], [3, "decision", "2024-06-26T12:33:38.249Z"]], "sent_back"],
  ["73c46945-0a6c-4b3a-a828-661de16edd79", "2024-06-24T16:15:46.909Z", "00061702-ce7b-4dc8-bc6c-ec13cf0ceae2", 3, [[1, "new_version", "2024-06-24T16:15:47.492Z"], [1, "assignment", "2024-06-25T12:48:42.862Z"], [1, "send_back", "2024-06-25T12:51:32.494Z"], [3, "provider_updated", "2024-06-25T15:10:08.417+00:00"], [3, "assignment", "2024-06-26T12:29:08.640Z"], [3, "decision", "2024-06-26T12:33:38.249Z"]], "provider_updated"],
  ["bd080793-01d5-4882-9b42-360f123ec8b7", "2024-06-24T16:15:46.909Z", "00061702-ce7b-4dc8-bc6c-ec13cf0ceae2", 1, [[1, "new_version", "2024-06-24T16:15:47.492Z"], [1, "assignment", "2024-06-25T12:48:42.862Z"], [1, "send_back", "2024-06-25T12:51:32.494Z"], [3, "provider_updated", "2024-06-25T15:10:08.417+00:00"], [3, "assignment", "2024-06-26T12:29:08.640Z"], [3, "decision", "2024-06-26T12:33:38.249Z"]], "submitted"],
  ["fcc2f94e-a2bd-422e-b59a-53210fa52bd5", "2024-06-26T12:33:38.249Z", "00061702-ce7b-4dc8-bc6c-ec13cf0ceae2", 4, [[1, "new_version", "2024-06-24T16:15:47.492Z"], [1, "assignment", "2024-06-25T12:48:42.862Z"], [1, "send_back", "2024-06-25T12:51:32.494Z"], [3, "provider_updated", "2024-06-25T15:10:08.417+00:00"], [3, "assignment", "2024-06-26T12:29:08.640Z"], [3, "decision", "2024-06-26T12:33:38.249Z"]], "granted"]
]

applications = {}
data.each do |ver_id, ver_updated_at, app_id, ver_version, events_array, ver_status|
  application = applications[app_id] ||= Submission.find_by(id: app_id) || begin
    events = events_array.map do |event_ver, event_type, event_updated_at|
      {
        id: SecureRandom.uuid,
        event_type:,
        updated_at: event_updated_at,
        submission_version: event_ver,
      }
    end
    FactoryBot.create(:event_submission, id: app_id, events:)
  end

  next if SubmissionVersion.find_by(id: ver_id)

  app_hash = FactoryBot.build(:application,
                              status: ver_status,
                              updated_at: ver_updated_at,
                              created_at: Time.new(2024, 1, 1))
  FactoryBot.create(:submission_version, submission: application, application: app_hash, version: ver_version, id: ver_id)
end
