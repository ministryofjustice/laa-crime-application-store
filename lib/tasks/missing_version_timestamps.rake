desc "One off tasks to fix missing submission version timestamps"
namespace :missing_version_timestamps do

  desc "When the latest record missed the required timestamp"
  task tranch1: :environment do
    SubmissionVersion.where(created_at: nil)

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
          ver.save!
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
        version.update!(created_at: timestamp, updated_at: timestamp)
        submission = version.submission
        event = submission.events.detect do |event|
          event['event_type'] == 'provider_updated' &&
          event['created_at'].nil? &&
          event['submission_version'] == version.version
        end

        puts 'Updating timestamps on provider event'
        event['created_at'] = event['updated_at'] = timestamp
        submission.save!
      end
    end
  end
end