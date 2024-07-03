desc "One off tasks to fix missing submission version timestamps"
namespace :missing_version_timestamps do

  desc "When the latest record missed the required timestamp"
  task tranch1: :environment do
    puts "==============================="
    puts "Tranch 1"
    puts "These are where the submission version is greater than that on any of the events"
    puts "This means we can use the updated_at time from the submission as it would be set"
    puts "when the version was created"
    puts "==============================="
    puts ""
    puts "Running check against expected list of ID's"
    results = ActiveRecord::Base.connection.exec_query(
      "select ver.id
      from (
            select max(version) as max_ver, id
            from (
              select (jsonb_array_elements(events) ->> 'submission_version')::integer as version, id from application
            ) as sub1 group by id
          ) as sub2
      join application_version as ver on ver.application_id = sub2.id
      where ver.created_at is null and sub2.max_ver < ver.version"
    )

    expected_ids = [
      "15079b48-7335-4733-b74f-d3e5a8da6403", "174c8be9-b2f5-4abd-9b64-66a2e8bf8d84", "21d7d673-e26b-40a6-a3d9-2d8ab728b979",
      "2a2fafa9-4ef0-48fb-8a8f-eb97450dfc97", "429a3baa-d66c-411a-9ae4-e2c2838fcdef", "56fc1668-9fa2-4eb5-9e8f-d7dda4b36e93",
      "69cde54e-9220-4e4c-b7c4-2975e6472ab3", "70076a3d-a51a-472c-924d-c23b1f7ccac2", "75201b9a-ee53-4570-bfe3-7a8413e811ee",
      "77cfa567-8652-4a68-811b-31ef5cd77b25", "878cc202-f8a6-4cda-9e0a-f0494ff8af11", "8a4305fb-e155-42e4-9d90-d2721cd6c2f3",
      "99cbe8eb-c796-4330-91e8-b784d936943f", "b6d37438-3783-446d-a0dc-0de3e47e1a89", "be860b2a-9c85-446e-a5cd-aa78bf8b99e3",
      "c709aa9f-03bb-48d7-9f44-109940347f97", "ebd5e8dc-fa78-4533-97be-492b9bde79c3", "f2bce0eb-4ba4-44fe-a4e1-6ae68e1038a3",
      "fa510af9-4607-47bc-8388-d2980355b09c"
    ]

    if results.rows.empty?
      puts "No results found..."
      puts "Skipping this update.."
    elsif results.rows.flatten.sort != expected_ids
      puts "ID's did not match expected.."
      puts "GOT: #{results.rows.flatten.inspect}"
      puts "Expected: #{results.rows.flatten.inspect}"
      puts ''
      puts "Exiting"
      exit
    else
      puts "ID's matched expected"
      puts "Updating timestamps for: #{expected_ids.inspect}"
      ActiveRecord::Base.connection.transaction do
        SubmissionVersion.where(id: expected_ids).includes(:submission).each do |ver|
          ver.created_at = ver.updated_at = ver.submission.updated_at
          ver.save!(touch: false)
        end
      end
    end
  end

  desc "Special case when provider_update as need to lookup from caseworker"
  task tranch2: :environment do
    puts "==============================="
    puts "Tranch 2"
    puts "These are provider_updated events that don't have a timestamp"
    puts "These rae manually set based off data looked up from CW app when the data was synced across"
    puts "==============================="
    puts ""

    # query to find records with missing data
    # SubmissionVersion.where(created_at: nil).where("application ->> 'status' = 'provider_updated'").order(:application_id, :id).pluck(:id, :application_id)
    # =>
    # [["155c385e-0ef4-4d5a-813f-ac827d02d2b4", "07988f26-cfaa-4fdf-8dda-f633793d6105"],
    # ["cfb73028-5531-46df-bcc5-f0fd4a2f7cfd", "7a5c8e58-a744-4a6f-8520-f3be563de3bc"],
    # ["6d73549a-316c-4b3e-9af6-352030b6fe01", "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0"],
    # ["95a18e65-9b97-43aa-af11-008684d3dc47", "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0"],
    # ["e71f8764-6c30-4ade-b9cc-7007f881ec48", "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0"],
    # ["b0f9423b-71c0-4685-bf84-6dc58bb2a8a6", "a9bb92f1-de30-4cda-9ae2-b4d76a533033"],
    # ["ee26fbc8-e1b9-49e5-827b-196ed15662a0", "d2aaf9f0-b53e-471f-acd8-5ff572a16e13"]]

    # query to obtain data:
    # Event.where(submission_id: ["88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0",
    #   "7a5c8e58-a744-4a6f-8520-f3be563de3bc",
    #   "07988f26-cfaa-4fdf-8dda-f633793d6105",
    #   "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0",
    #   "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0",
    #   "a9bb92f1-de30-4cda-9ae2-b4d76a533033",
    #   "d2aaf9f0-b53e-471f-acd8-5ff572a16e13"
    # ], event_type: "Event::ProviderUpdated").pluck(:submission_id, :created_at)
    # =>
    # [["07988f26-cfaa-4fdf-8dda-f633793d6105", Tue, 11 Jun 2024 08:12:49.374763000 UTC +00:00],
    # ["7a5c8e58-a744-4a6f-8520-f3be563de3bc", Tue, 11 Jun 2024 08:19:59.650678000 UTC +00:00],
    # ["88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", Thu, 13 Jun 2024 15:15:07.656617000 UTC +00:00],
    # ["88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", Tue, 11 Jun 2024 15:29:32.802009000 UTC +00:00],
    # ["88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", Fri, 14 Jun 2024 12:19:16.311660000 UTC +00:00],
    # ["a9bb92f1-de30-4cda-9ae2-b4d76a533033", Mon, 17 Jun 2024 14:48:47.026644000 UTC +00:00],
    # ["d2aaf9f0-b53e-471f-acd8-5ff572a16e13", Mon, 17 Jun 2024 14:46:57.466402000 UTC +00:00],
    # ["d2aaf9f0-b53e-471f-acd8-5ff572a16e13", Tue, 18 Jun 2024 13:25:51.455163000 UTC +00:00]]

    # NOTE: 2 records returned for d2aaf9f0-b53e-471f-acd8-5ff572a16e13 when only 1 expect, existing time removed
    # NOTE: 3 records for "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", these order based on version before assigning times

    # version_id, submission_id, provider_updated (created_at from CW)
    updates = [
      ["155c385e-0ef4-4d5a-813f-ac827d02d2b4", "07988f26-cfaa-4fdf-8dda-f633793d6105", DateTime.parse("Tue, 11 Jun 2024 08:12:49.374763000 UTC +00:00")],
      ["cfb73028-5531-46df-bcc5-f0fd4a2f7cfd", "7a5c8e58-a744-4a6f-8520-f3be563de3bc", DateTime.parse("Tue, 11 Jun 2024 08:19:59.650678000 UTC +00:00")],
      ["e71f8764-6c30-4ade-b9cc-7007f881ec48", "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", DateTime.parse("Tue, 11 Jun 2024 15:29:32.802009000 UTC +00:00")],
      ["6d73549a-316c-4b3e-9af6-352030b6fe01", "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", DateTime.parse("Thu, 13 Jun 2024 15:15:07.656617000 UTC +00:00")],
      ["95a18e65-9b97-43aa-af11-008684d3dc47", "88a7bd7b-7cac-4a11-b13c-b6ddc187f4d0", DateTime.parse("Fri, 14 Jun 2024 12:19:16.311660000 UTC +00:00")],
      ["b0f9423b-71c0-4685-bf84-6dc58bb2a8a6", "a9bb92f1-de30-4cda-9ae2-b4d76a533033", DateTime.parse("Mon, 17 Jun 2024 14:48:47.026644000 UTC +00:00")],
      ["ee26fbc8-e1b9-49e5-827b-196ed15662a0", "d2aaf9f0-b53e-471f-acd8-5ff572a16e13", DateTime.parse("Mon, 17 Jun 2024 14:46:57.466402000 UTC +00:00")],
    ]

    puts "Updating records..."
    puts updates.inspect

    ActiveRecord::Base.connection.transaction do
      updates.each do |version_id, submission_id, timestamp|
        version = SubmissionVersion.find(version_id)
        version.assign_attributes(created_at: timestamp, updated_at: timestamp)
        version.save!(touch: false)
        submission = version.submission
        event = submission.events.detect do |event|
          event['event_type'] == 'provider_updated' &&
          event['created_at'].nil?
        end

        puts 'Updating timestamps on provider event'
        event['created_at'] = event['updated_at'] = timestamp
        # NOTE: version on provider_updated was set incorrectly in db/migrate/20240628155626_missing_event_fields.rb
        # it was set as last event version + 1, but the sent_back event with the same version as the sent back version
        # it is sent on the one before (which is what was present in CW when the event was created)
        # this is not a big deal as we don't use the version anywhere.
        event['submission_version'] = version.version
        submission.save!(touch: false)
      end
    end
  end

  task tranch3: :environment do
    # query to check when created_at on event is wrong
    # ActiveRecord::Base.connection.exec_query("
    #   select av.id as app_id, all_events.event_id, all_events.event_at, av.created_at, all_events.submission_version, av.version
    #   from all_events
    #   left join application_version av on
    #     all_events.submission_version in (av.version - 1, av.version) and
    #     av.application ->> 'status' = 'provider_updated' and
    #     all_events.id = av.application_id
    #   where event_type = 'provider_updated'
    #   order by 3
    # ").pluck('app_id', 'event_id', 'event_at', 'created_at', 'submission_version', 'version')
    results = [
      ["155c385e-0ef4-4d5a-813f-ac827d02d2b4", "fb8620b4-8c9c-4542-84d5-eef8451c98ee", "2024-06-11 08:12:49.374 UTC", "2024-06-11 08:12:49.374763 UTC", 3, 3],
      ["cfb73028-5531-46df-bcc5-f0fd4a2f7cfd", "7ac70f46-e63e-439b-a8f7-8faa378e56f8", "2024-06-11 08:19:59.65 UTC", "2024-06-11 08:19:59.650678 UTC", 3, 3],
      ["e71f8764-6c30-4ade-b9cc-7007f881ec48", "cdf51b41-d633-4a8c-93ee-d2da8494f661", "2024-06-11 15:29:32.802 UTC", "2024-06-11 15:29:32.802009 UTC", 3, 3],
      ["6d73549a-316c-4b3e-9af6-352030b6fe01", "1f03be18-ed56-4e16-a90f-b40ecb1b2865", "2024-06-13 15:15:07.656 UTC", "2024-06-13 15:15:07.656617 UTC", 6, 6],
      ["95a18e65-9b97-43aa-af11-008684d3dc47", "4c72a40a-df29-4dce-881e-6b082b1bb234", "2024-06-14 12:19:16.311 UTC", "2024-06-14 12:19:16.31166 UTC", 8, 8],
      ["ee26fbc8-e1b9-49e5-827b-196ed15662a0", "de14d863-f3a3-4451-adf3-7d6e3956b963", "2024-06-17 14:46:57.466 UTC", "2024-06-17 14:46:57.466402 UTC", 3, 3],
      ["b0f9423b-71c0-4685-bf84-6dc58bb2a8a6", "d1142f84-6cbc-459c-9346-df5e5a0c57de", "2024-06-17 14:48:47.026 UTC", "2024-06-17 14:48:47.026644 UTC", 3, 3],
      ["7d931f3c-192b-41b9-85f8-9a76868be934", "e81012b0-1098-420c-967c-ebe021232cac", "2024-06-18 08:17:44.194 UTC", "2024-06-18 08:53:55.468969 UTC", 2, 3],
      ["b5b1dfb8-683d-41c7-be7a-30a814e812c9", "7b530fb5-d279-4c76-be86-baa52e5ceaa8", "2024-06-18 10:00:07.966 UTC", "2024-06-18 13:25:50.861558 UTC", 4, 5],
      ["4d251450-5e66-4ee4-a48c-8c5213ce1731", "572455ff-7678-42c3-9451-482c8ca82dd1", "2024-06-19 09:55:09.497 UTC", "2024-06-20 09:42:11.207836 UTC", 4, 5],
      ["2e1ca687-5fa6-44ad-81cc-a59c1e2cb8db", "95254b9b-4f2c-4da0-9194-dbb6445bbc1f", "2024-06-19 10:03:27.31 UTC", "2024-06-19 16:31:12.297594 UTC", 2, 3],
      ["1b390bcb-edc6-434e-abc0-a5483031704d", "ee222910-e806-4736-bc34-db7dff67a5b0", "2024-06-19 12:53:06.434 UTC", "2024-06-24 11:12:35.36563 UTC", 2, 3],
      ["0085f9e4-9285-4f3d-b90b-5f2467f456ce", "a007aa8d-3398-47e7-9149-37c007a78d8f", "2024-06-21 09:29:39.368 UTC", "2024-06-24 18:46:08.845792 UTC", 2, 3],
      ["2ee23c3d-6ab8-4266-8aa3-257d4a639c32", "daf086fe-db37-4bdc-ba82-e8feb2b3d4f2", "2024-06-21 09:34:31.596 UTC", "2024-06-24 19:13:44.262086 UTC", 2, 3],
      ["8f06c9cf-5d4d-4a6f-ab5d-dc9fa8d2545d", "21bce7bd-bdf0-46b2-b402-78a7774eed1a", "2024-06-21 09:44:18.179 UTC", "2024-06-21 10:51:49.470452 UTC", 6, 7],
      ["ba06b845-4cdc-41ca-b023-78ed0f93fda4", "f0a75c46-a216-44ae-9650-4825bfd274a7", "2024-06-21 09:47:27.848 UTC", "2024-06-21 13:34:19.316017 UTC", 2, 3],
      ["3c58aca0-4467-49e9-9b25-b75ffd32c88d", "78e42902-3e09-412b-9855-c144b3f66bff", "2024-06-21 09:58:24.27 UTC", "2024-06-25 09:03:04.836337 UTC", 2, 3],
      ["5e6d3478-2aa4-48d3-9aad-f66aee0dcfdd", "9fe6bf17-cabe-4006-a5f9-23cb47042046", "2024-06-24 11:48:53.55 UTC", "2024-06-24 12:32:38.979683 UTC", 2, 3],
      ["6097f260-6dce-4d1c-815e-bab43c57fd74", "d9b1206d-c79a-4b0d-ab0c-8b117ad117b7", "2024-06-24 12:10:26.774 UTC", "2024-06-25 13:25:15.715172 UTC", 4, 5],
      ["f46a6ef7-2296-42ce-acc2-a1307c3f854c", "24b94e77-33b9-4762-8e10-b37aac693ac0", "2024-06-25 12:51:40.107 UTC", "2024-06-25 15:10:08.417587 UTC", 2, 3],
      ["89e21b01-87d9-4047-ba48-f4a13ec3f52c", "e051b524-999f-42bc-b023-b900a826d26a", "2024-06-25 12:59:31.927 UTC", "2024-06-25 13:32:15.581912 UTC", 4, 5],
      ["938b0df7-0a40-42ed-b44c-723874fd3ec5", "31f321d2-4d10-4e91-af4a-39178fb3e2fd", "2024-06-25 13:06:50.878 UTC", "2024-06-25 13:31:28.788551 UTC", 4, 5],
      ["7bab6948-67ae-4393-9cee-e7354fbe03f3", "bc4f1bbc-d126-4bdc-bb7b-367bbe4aaf18", "2024-06-26 13:14:14.465 UTC", "2024-06-26 13:15:55.315083 UTC", 6, 7],
      ["bf8b050a-5531-4dcb-aaae-04c2248fa119", "7c6ec4d3-11a1-4a72-8294-a94d6674d886", "2024-07-01 16:27:25.537 UTC", "2024-07-01 16:27:25.541797 UTC", 3, 3],
      ["0b0c841a-16ed-49dd-8065-5b1d8093d922", "dc411cd4-e410-47d0-9648-ba424e4172df", "2024-07-02 11:45:19.42 UTC", "2024-07-02 11:45:19.425862 UTC", 3, 3],
      ["43f9fc65-190c-4e74-8adb-da8e0ca8b153", "55f3a8d9-a690-43a5-828a-96cc67077d2f", "2024-07-03 08:29:50.33 UTC", "2024-07-03 08:29:50.336717 UTC", 3, 3],
      ["e9203bd0-254d-471a-845f-bd0975db3720", "314bf52e-628e-4bdb-a323-35ac2bb0e67f", "2024-07-03 08:50:07.636 UTC", "2024-07-03 08:50:07.641403 UTC", 3, 3]
    ]

    ActiveRecord::Base.connection.transaction do
      results.each do |application_id, event_id, event_time, version_time, event_version, version_version|
        if (DateTime.parse(event_time).to_i - DateTime.parse(version_time).to_i).abs < 10
          puts "skipping record: #{application_id}: #{event_id}.."
          next
        end

        puts "Updating record: #{application_id}: #{event_id}.. #{event_time} to #{version_time} and #{event_version} to #{version_version}"
        submisison = Submission.find(application_id)
        event = submisison.events.detect { |eve| eve['id'] == event_id } || raise

        event['created_at'] = event['updated_at'] = DataTime.parse(version_time)
        event['submission_version'] = version_version
        submission.save!(touch: false)
      end
    end
  end
end