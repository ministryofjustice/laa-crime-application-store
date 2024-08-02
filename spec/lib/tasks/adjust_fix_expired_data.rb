# This contains the used bits of data to replicate the updated_at issues related to expiry events having the same version as sent_back events
# issue that currently exists in Production

require "factory_bot"

# query used to extract the data
# irb(main):005> puts Submission.where(application_state: 'expired')
#   .flat_map { |sub| sub.ordered_submission_versions.map { |ver|
#     [ver.application_id, ver.id, ver.submission.application_state, ver.application['status'], ver.application['updated_at'], ver.submission.events.map { |eve| [eve['id'], eve['event_type'], eve['updated_at'], eve['submission_version']] }, ver.submission.current_version, ver.version] }
#   }.inspect
data = [
  ["fcc2f94e-a2bd-422e-b59a-53210fa52bd5", "76254e88-854d-46b2-ac9b-9544b11e494a", "expired", "expired", "2024-07-25T21:16:05.753Z", [["1896e445-2af2-4486-8f03-af34371cc370", "new_version", "2024-07-10T11:10:16.456Z", 1], ["c775ad35-31c3-4aba-b202-59992a61bc3a", "assignment", "2024-07-11T11:35:48.419Z", 1], ["884c5af0-5f57-4981-8408-eb7e9cff4fc5", "send_back", "2024-07-11T11:38:56.864Z", 1], ["69912c62-aea2-4690-867a-707facf93fc6", "expiry", "2024-07-25T21:16:05.753Z", 1]], 3, 3],
  ["fcc2f94e-a2bd-422e-b59a-53210fa52bd5", "fca53634-333d-455e-9ec1-210814f42b35", "expired", "sent_back", "2024-07-25T21:16:05.753Z", [["1896e445-2af2-4486-8f03-af34371cc370", "new_version", "2024-07-10T11:10:16.456Z", 1], ["c775ad35-31c3-4aba-b202-59992a61bc3a", "assignment", "2024-07-11T11:35:48.419Z", 1], ["884c5af0-5f57-4981-8408-eb7e9cff4fc5", "send_back", "2024-07-11T11:38:56.864Z", 1], ["69912c62-aea2-4690-867a-707facf93fc6", "expiry", "2024-07-25T21:16:05.753Z", 1]], 3, 2],
  ["fcc2f94e-a2bd-422e-b59a-53210fa52bd5", "27cd14d8-df8a-4dda-8ae3-8c44047c5a06", "expired", "submitted", "2024-07-10T11:10:16.342Z", [["1896e445-2af2-4486-8f03-af34371cc370", "new_version", "2024-07-10T11:10:16.456Z", 1], ["c775ad35-31c3-4aba-b202-59992a61bc3a", "assignment", "2024-07-11T11:35:48.419Z", 1], ["884c5af0-5f57-4981-8408-eb7e9cff4fc5", "send_back", "2024-07-11T11:38:56.864Z", 1], ["69912c62-aea2-4690-867a-707facf93fc6", "expiry", "2024-07-25T21:16:05.753Z", 1]], 3, 1],
  ["73c46945-0a6c-4b3a-a828-661de16edd79", "dbd9e16e-1449-44b5-8efa-e37144fb4747", "expired", "expired", "2024-07-25T21:16:05.741Z", [["fee1ca3c-9e86-4c7e-85db-866351a62cb2", "new_version", "2024-07-10T12:00:26.313Z", 1], ["b7393b8f-81e5-4096-a233-4e5632269ce1", "assignment", "2024-07-11T11:51:48.282Z", 1], ["fcfd94fd-ddc4-4382-afd6-2fc4346392a0", "send_back", "2024-07-11T11:54:55.602Z", 1], ["fef670a5-1375-4977-80ee-809df936b761", "expiry", "2024-07-25T21:16:05.741Z", 1]], 3, 3],
  ["73c46945-0a6c-4b3a-a828-661de16edd79", "eecec8c6-f82d-4a9d-85d1-7626cbf43942", "expired", "sent_back", "2024-07-25T21:16:05.741Z", [["fee1ca3c-9e86-4c7e-85db-866351a62cb2", "new_version", "2024-07-10T12:00:26.313Z", 1], ["b7393b8f-81e5-4096-a233-4e5632269ce1", "assignment", "2024-07-11T11:51:48.282Z", 1], ["fcfd94fd-ddc4-4382-afd6-2fc4346392a0", "send_back", "2024-07-11T11:54:55.602Z", 1], ["fef670a5-1375-4977-80ee-809df936b761", "expiry", "2024-07-25T21:16:05.741Z", 1]], 3, 2],
  ["73c46945-0a6c-4b3a-a828-661de16edd79", "7fe84cdb-fe96-4b70-b4ca-30c4f11cc9f6", "expired", "submitted", "2024-07-10T12:00:25.987Z", [["fee1ca3c-9e86-4c7e-85db-866351a62cb2", "new_version", "2024-07-10T12:00:26.313Z", 1], ["b7393b8f-81e5-4096-a233-4e5632269ce1", "assignment", "2024-07-11T11:51:48.282Z", 1], ["fcfd94fd-ddc4-4382-afd6-2fc4346392a0", "send_back", "2024-07-11T11:54:55.602Z", 1], ["fef670a5-1375-4977-80ee-809df936b761", "expiry", "2024-07-25T21:16:05.741Z", 1]], 3, 1],
  ["14994bfc-95c2-4ddb-94a0-1b84cbc1f7f0", "274eac2a-44db-4a92-bcb8-3c5878f64bed", "expired", "expired", "2024-07-23T21:16:08.493Z", [["c3870d15-cafe-4e9f-b4fa-3c0036111e1e", "new_version", "2024-07-08T09:59:08.404Z", 1], ["dffea96a-f3cb-45c9-96b7-42124b2908d0", "assignment", "2024-07-09T10:04:08.201Z", 1], ["90cf399c-02ec-4bf0-876b-c23e300add46", "send_back", "2024-07-09T10:09:03.314Z", 1], ["75367256-94a1-4c69-a07c-c86b3de3a9f1", "expiry", "2024-07-23T21:16:08.493Z", 1]], 3, 3],
  ["14994bfc-95c2-4ddb-94a0-1b84cbc1f7f0", "f024d2f5-f1c9-425f-b649-cdb9a4c01f6b", "expired", "sent_back", "2024-07-23T21:16:08.493Z", [["c3870d15-cafe-4e9f-b4fa-3c0036111e1e", "new_version", "2024-07-08T09:59:08.404Z", 1], ["dffea96a-f3cb-45c9-96b7-42124b2908d0", "assignment", "2024-07-09T10:04:08.201Z", 1], ["90cf399c-02ec-4bf0-876b-c23e300add46", "send_back", "2024-07-09T10:09:03.314Z", 1], ["75367256-94a1-4c69-a07c-c86b3de3a9f1", "expiry", "2024-07-23T21:16:08.493Z", 1]], 3, 2],
  ["14994bfc-95c2-4ddb-94a0-1b84cbc1f7f0", "8b24405e-3fd2-499a-8716-358e9f4ef736", "expired", "submitted", "2024-07-08T09:59:07.941Z", [["c3870d15-cafe-4e9f-b4fa-3c0036111e1e", "new_version", "2024-07-08T09:59:08.404Z", 1], ["dffea96a-f3cb-45c9-96b7-42124b2908d0", "assignment", "2024-07-09T10:04:08.201Z", 1], ["90cf399c-02ec-4bf0-876b-c23e300add46", "send_back", "2024-07-09T10:09:03.314Z", 1], ["75367256-94a1-4c69-a07c-c86b3de3a9f1", "expiry", "2024-07-23T21:16:08.493Z", 1]], 3, 1],
  ["bd080793-01d5-4882-9b42-360f123ec8b7", "574f3abe-4eeb-432c-9960-ca92317a9cb4", "expired", "expired", "2024-07-29T21:16:02.692Z", [["6f82a2e2-c8dc-43a0-8a6e-460f25a5a851", "new_version", "2024-07-12T11:23:05.969Z", 1], ["e62ed449-97a1-4281-b881-14e747109e40", "assignment", "2024-07-15T14:09:45.559Z", 1], ["4df2845b-6d4c-42c9-ab6e-2c06ecc0702f", "send_back", "2024-07-15T14:12:40.335Z", 1], ["a5610650-299d-4278-9d89-d7cc459e8c71", "expiry", "2024-07-29T21:16:02.692Z", 1]], 3, 3],
  ["bd080793-01d5-4882-9b42-360f123ec8b7", "3038c9ad-9090-4e57-b86b-3ba35a4723d3", "expired", "sent_back", "2024-07-29T21:16:02.692Z", [["6f82a2e2-c8dc-43a0-8a6e-460f25a5a851", "new_version", "2024-07-12T11:23:05.969Z", 1], ["e62ed449-97a1-4281-b881-14e747109e40", "assignment", "2024-07-15T14:09:45.559Z", 1], ["4df2845b-6d4c-42c9-ab6e-2c06ecc0702f", "send_back", "2024-07-15T14:12:40.335Z", 1], ["a5610650-299d-4278-9d89-d7cc459e8c71", "expiry", "2024-07-29T21:16:02.692Z", 1]], 3, 2],
  ["bd080793-01d5-4882-9b42-360f123ec8b7", "3f61c3b5-4453-4e58-865c-a44369c8a590", "expired", "submitted", "2024-07-12T11:23:05.662Z", [["6f82a2e2-c8dc-43a0-8a6e-460f25a5a851", "new_version", "2024-07-12T11:23:05.969Z", 1], ["e62ed449-97a1-4281-b881-14e747109e40", "assignment", "2024-07-15T14:09:45.559Z", 1], ["4df2845b-6d4c-42c9-ab6e-2c06ecc0702f", "send_back", "2024-07-15T14:12:40.335Z", 1], ["a5610650-299d-4278-9d89-d7cc459e8c71", "expiry", "2024-07-29T21:16:02.692Z", 1]], 3, 1]
]


applications = {}
data.each do |app_id, ver_id, app_state, ver_status, ver_updated_at, events_array, app_version, ver_version|
  application = applications[app_id] ||= Submission.find_by(id: app_id) || begin
    events = events_array.map do |event_id, event_type, event_updated_at, event_ver|
      {
        id: event_id,
        event_type:,
        updated_at: event_updated_at,
        submission_version: event_ver,
      }
    end
    FactoryBot.create(:event_submission, id: app_id, current_version: app_version, application_state: app_state, events:)
  end

  next if SubmissionVersion.find_by(id: ver_id)

  app_hash = FactoryBot.build(:application,
                              status: ver_status,
                              updated_at: ver_updated_at)
  FactoryBot.create(:submission_version, submission: application, application: app_hash, version: ver_version, id: ver_id)
end
