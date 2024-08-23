
namespace :adjust do
  desc "Change the status of an application"
  task :status, [:submission_id, :status, :role_to_notify] => :environment do |_, args|
    submission = Submission.find(args.submission_id)
    submission.update!(application_state: args.status)

    next if args.role_to_notify.blank?

    Subscriber.where(subscriber_type: args.role_to_notify).find_each do |subscriber|
      NotifySubscriber.new.perform(subscriber.id, submission.id)
    end
  end

  desc "Set the updated at on historical caseworker versions"
  task updated_at: :environment do
    caseworker_statuses = %w[granted rejected auto_grant part_grant sent_back expired]
    versions = SubmissionVersion.includes(:submission)
                                .where(Arel.sql("application ->> 'status' in (?)", caseworker_statuses))

    versions.each do |version|
      event_for_version = version.submission.events.filter { _1['submission_version'] == (version.version - 1) }
      event = event_for_version.sort_by { _1['updated_at'] }.last

      unless event
        puts "Missing Event #{version.application_id}:#{version.id} from #{version.application['updated_at']}"
        next
      end

      puts "updating #{version.application_id}:#{version.id} from #{version.application['updated_at']} to #{event['updated_at']} FROM #{event['event_type']}"
      version.application['updated_at'] = event['updated_at']

      version.save if ENV['PERSIST_ADJUSTMENT']
    end
  end

  desc "Correct set state in JSON blob"
  task update_state: :environment do
    versions = SubmissionVersion.includes(:submission)
                .joins("join application_version av on av.application_id = application_version.application_id and " \
                      "av.application ->> 'status' = application_version.application ->> 'status' and " \
                      "av.version = application_version.version - 1")


    versions.each do |version|
      if version.version != version.submission.current_version
        puts "Not the last version (believe these are duplicates) #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}, version: #{version.version},  current: #{version.submission.current_version}"
        next
      end

      event_for_version = version.submission.events.filter do
        _1['submission_version'] == (version.version - (version.submission.application_state == 'expired' ? 2 : 1))
      end
      event = event_for_version.sort_by { _1['updated_at'] }.last

      unless event
        puts "Missing Event #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}"
        next
      end

      if version.submission.application_state.in?(["auto_grant", "expired", "grant", "part_grant"])
        puts "Updating #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}"
        version.application['status'] = version.submission.application_state
        version.application['updated_at'] = event['updated_at']

        version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
      else
        puts "Unknown status #{version.application_id}:#{version.id} from #{version.application['status']} to #{version.submission.application_state}"
      end
    end
  end

  desc "Fix updated at on last sent back before expiry as expiry version does not update"
  task fix_expired: :environment do
    Submission.where(application_state: 'expired').each do |submission|
      version = submission.ordered_submission_versions[1]
      wrong_event = submission.events.filter { _1['submission_version'] == (version.version - 1) }
                              .sort_by { _1['updated_at'] }.last
      right_event = submission.events.filter { _1['submission_version'] == (version.version - 1) && _1['event_type'] != 'expiry' }
                              .sort_by { _1['updated_at'] }.last

      if wrong_event['updated_at'] != right_event['updated_at'] && version.application['updated_at'] == wrong_event['updated_at']
        puts "Fixing incorrect time #{submission.id}:#{version.id} from #{wrong_event['updated_at']} to #{right_event['updated_at']}"
        version.application['updated_at'] = right_event['updated_at']
        version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
      else
        puts "Time fix not found for #{submission.id}:#{version.id}"
      end
    end
  end

  desc "Fix applications that did not get status update before being sent across"
  task fix_status: :environment do
    versions = SubmissionVersion.where(Arel.sql('application ->> \'status\' = \'draft\'')).where(version: 1)
    versions.each do |version|
      puts "Updating ID: #{version.application_id}, Version: #{version.version} from #{version.application['status']} to submitted"
      version.application['status'] = 'submitted'
      version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
    end
  end

  desc "Fix timestamp on Provider updated where was previous set incorrectly"
  task fix_provider_updated: :environment do
    processing_time = Class.new(ApplicationRecord) do
      self.table_name = :processing_times
    end
    records = processing_time.where(Arel.sql('from_time > to_time')).where(to_status: 'provider_updated')

    records.each do |record|
      version = SubmissionVersion.find_by(application_id: record.id, version: record.version)
      event = version.submission.events.detect { _1['submission_version'] == record.version && _1['event_type'] == 'provider_updated' }

      if event.nil?
        puts "Skipping as no event: #{record.id}, Version: #{record.version}"
      elsif event['created_at'] == version.application['updated_at']
        puts "Skipping as no change ID: #{record.id}, Version: #{record.version}"      else
        puts "Updating ID: #{record.id}, Version: #{record.version} from #{version.application['updated_at']} to #{event['created_at']}"
        version.application['updated_at'] = event['created_at']
        version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
      end
    end
  end

  desc "Fix updated at on previous draft records as it can be multiple days out"
  task fix_draft_updated_at: :environment do
    ids = [
      '651a7068-c6a1-4d99-a735-b41f5a5fd4e5', 'c4a88056-b2d0-4f6b-9e33-4a5b802b0548', '2288c8dd-fa4a-43c6-a391-8c7929bff58c', '206429e7-9c08-4c25-b9ea-33a7423a0ced', '147c9ced-2890-45a7-92a2-5bceeb391ecd', 'c94644e2-c3e7-43a5-9fbf-cf4cb0bc5fd0', '614ab6d0-9a8e-4b4b-a7da-9f4e3ad529b2', '2c1179f1-c063-4c02-a801-235e43300365', 'aae31565-bf72-44de-baa2-1de7b21cb3a9', '5ec02827-e546-41fb-8eb3-7185102ce45a', '78c00d52-ca10-42cd-900d-2fd8e49aa89d', '31b11f56-a612-4f45-acd8-2432a3d37374', '0f097924-5952-4d81-8f09-6b3b85a5674d', 'a679add0-e79c-4bd2-bb1c-d83200d6a04f', 'c9eb4ed8-1a19-480f-a744-f1a3cd59f423', '11e5b16c-b414-4eac-bd84-1419760a90da', 'ad084bba-f173-4779-acb5-e6b706594b06', '615253dc-081e-435e-b6d9-3be8c557e743', '19fe560e-7c65-4f68-9427-472ac2145956', '8f6f6671-76b7-4814-8ffb-de21af0429b6', '2895672b-aa05-449e-b179-b8fdd1991b06', '87c04af9-b0d5-4ab3-bfe8-8f4b140a458a', 'e5bea6d1-f93f-4e92-962f-c2b1f506712f', '1dfc67cb-37a3-4345-a4c0-8c13dc0b73e5',
      '7b249854-35c2-4156-8f45-4f57e7763a66', 'd6da7425-97bb-43b7-98d9-401a620eb3f6', 'e97c8a92-28cc-4512-9faf-120b90438bae', 'a059f294-6926-491a-a8ab-15ed17c417db', '47ac44c6-2105-4f1b-b676-940938fd6c99', '01e31fbc-0dea-4335-a9f8-c02f3d959b48', '54559a1e-1c63-43af-a9e9-456360be1df4', '275de5e2-7b0c-42f4-ae46-99ddbb990897', '074fcc45-5071-4780-ac0d-4e4b9e9642e2', '608f1f5f-8314-4475-981c-16dcbf1d7848', '9e6c718b-59b2-4545-a5ab-6563f43f75e8', '3fc361d2-e215-41fa-a4c2-f375e9efaeff', '606e3cbe-bf88-49b7-8387-6c19e1374c6c', '1290f9c9-654b-4d9d-8e45-40e24bd2bb81', '16a7546c-e9f6-4ecf-9862-03fb40bc8a32', 'b9eb2489-404e-423c-ba47-94aa45fe36ca', '24a7a0fe-65d0-4391-a367-484806ab2a17', '27de3c91-c773-41ef-8f51-9f2fde6aa219', '6049be84-b569-4c9e-9e38-6050de695e51', '61601e1c-807a-4ff9-8f89-98e7fb04f467', '3df61183-4e43-437f-9701-c118ebb8734e', '72ac67a8-213d-4dc5-b3d3-7574bf8d2494', '6e73d071-9918-46a4-8976-1a6d9e62e00c', '60cf6319-7418-4c97-a889-44963913759d',
      '814f8d54-51be-4d6d-ae0c-ed46b3b1c2b0', 'dfd334f7-5ff6-4c14-834a-2c9dd6497627', '722cf506-e4bf-42b8-947d-df0b43d4af93', 'c6954b97-9fab-489d-a67a-0a0551a57426', 'de7cabb4-ad11-4d50-8e6d-f84c2803e805', 'b1169840-3506-4cfb-8f92-905f95566ccb', 'ab8c8399-cd36-453b-92bb-d1b2249b9bea', 'b833ae11-7930-4e32-a2f4-6553357f6705', '472cce4f-89ec-4838-a8bd-2267b7c99e43', 'a50cfe6a-c808-4231-9098-f12a0293e281', 'a8291b68-5257-46ca-9f3b-4b052e1d639b', '9fa6ba1c-ea3a-47eb-abb2-875744076640', '90f87f42-fe65-4c25-83e7-f3fb787a7871', 'ec65ce7a-aee2-48d4-9bfb-617f8b320cce', '6c14eaa0-c57e-45d0-9adb-24a656e98067', 'e1985976-250a-47dc-bd02-de0e4e85a820', 'fcde437c-38ed-4535-838b-33a6f0919bfb', 'b2637072-8288-4992-880c-b22437e9bb0a', '43263a1d-796a-4159-89a0-db9c0d365ab8', 'd7adb7f8-fa84-43ab-a59c-0a1332617347', 'a8835210-573f-4c39-828b-9bce1681bb0c', 'c9d067a8-df95-4342-8dd7-055ea0dfebb2', '4080b3a6-7e2b-4014-8714-06854f9bb287', 'fcc081d9-24c9-431e-a4c8-c11e5b0699db',
      '8762cd70-daad-48b1-b402-79e172b9e367', '2e896b80-cd25-4b23-b3ce-6f04cd4c9569', 'b2b7ce4f-22df-42fe-8b70-16bd2a22e900', 'd98c6475-9e47-4a45-b804-8c3fa239c838', 'd0bbe12f-11c1-4d25-b472-de07fb1c724f', 'eaf73f4a-9b51-4984-8bdc-6597dae984f6', '92e22329-ee66-48e2-9ce9-9174f9d3ef37', 'c1b330a7-4903-443b-b232-1d67f84021dd', '06946f58-83d6-40af-a421-94b98ac5bb8e', '6ded6769-c5a9-4b96-b4d1-077f5e7f3816', '554c8b24-b02c-414e-8b42-233d2b84e557', '35d403d3-08bd-49df-a790-b030c0790e22', '460acaff-125c-41e4-a1f9-4c29864e25f3', 'd8319950-200c-4b4d-ba96-2278c12bbc03', '9ef53888-a191-4c63-8ff5-2625f657d6d6', '8ffed827-4742-4b69-9b48-4f3ab5cba4c7', 'e460bd55-c2aa-4083-8a65-f35958986cc0', '55c2b1fb-8b01-46a5-ab70-4def9ef68c48', '3e8fa736-578e-451f-a6e6-1018e5b8e549', '4949c654-1b77-4a9a-be09-c8016d75d502', 'b706c1f5-62cf-498f-b011-e5169ed3dc75', '3ff852b0-59d4-48d5-9270-2665f843fa37', '1cd68ddf-f521-4f58-95e1-d9c29f964830', 'ce8638f7-8f86-46b3-b917-6887f2909e44',
      'a648785d-63ae-416a-af78-4e8f1fd32370', 'fc35be6a-3c6c-4752-b517-1353f1c443db', '66926978-0bd2-47bc-8c33-70dec35072fc', 'a814edde-8ce3-4872-b3f0-315047385ef3', 'd142f0b6-a04e-429a-9ba4-bb1482887463', 'bc3e0726-d1c5-42e7-b5a5-4dfa17d313c3', '44958a92-c3fa-412d-a890-354853cd7962', '6cbf8a99-c2ac-44c1-b7c3-9fa79f87749f', 'e41c03b4-5d47-47a7-87b6-6f029ffff58a', '1bd0376f-85dc-42a8-a6bb-1a33177acb77', 'd9deaecd-110f-4e2f-a38c-837787c96356', '3049a80c-ed96-4e44-91d5-7fe32f91bbe0', '4855b309-e68d-42b8-9d58-f7975b4dcaff', 'c6befa8c-9ba5-4385-819d-b16df5344090', '29170b86-d55c-4555-9f71-571e7738cb97', 'c97a824a-9beb-4ef2-ac57-eb1ffd463ca7', 'a3281b17-4a64-40d7-bc78-7d784cd59e7b', '329dc047-0a6e-49d3-a96c-11e1512ac0e5', '6a28db09-47b2-4f9f-9cc8-70ef3e116b45', 'e1a5e184-5174-4967-a8ac-0524079874d9', '5a8467f6-6fc4-46e2-97e9-72a906ae80c5', '6d506ab4-ea98-4b85-85e7-41b0d145551e', '532c4f6f-2b1e-403a-ba76-977dccfc8d35', 'f5dd77ff-c957-4bbf-9df8-0e01408a7718',
      '18f50cdd-00c8-4b52-a802-89792dcdb347', '9d238412-592e-4b80-adf9-a16c30160f4c', '12ef805d-ef3a-4360-b786-b480e05df75e', '511ad29e-2019-40b8-bf0b-23cbeb53d506', '6bb3bdf8-9f1a-4d86-9a37-a1b470d1edcb', 'f6a988c5-e087-4db6-913d-224b3351ecee', '0be3cd25-288d-48e2-a20e-fca89f9b71d5', '937039cb-febb-450b-abd4-f59076bd8706', '108b017b-a00c-4764-b377-8fb25e26d53c', '24dc033d-6368-40b2-a9cd-54063be7aa24', '39de628f-0713-40be-b0e3-12b4555b89b2', '025d5084-84c4-404e-b520-19364ba74126', '4013a7ba-849c-4ff8-9675-014a04bff008', '0d363c73-33a1-42cc-8aaa-201f6419e1ca', '6f8846bd-b412-4a49-a06f-eb1a38eaa519', 'd2cfb9d4-4a6e-494b-be07-2b22d78740ec', 'b8741ffc-7c7b-4025-a233-eaeeb2ca8542', '10e7c46b-2d70-4348-acae-7f38eb888480', '0cdd1277-192c-44f9-a79e-adb3cbe90b31', 'a93cd0a7-5330-4f15-b8f6-02b226bd8624', 'bf3b7e96-fc90-4b2d-8fdc-8f0d98c92cc7', '7c1d180b-3536-4d0c-a96a-c2ad9d7dd0bc', '90d765d2-465c-4229-a06f-2e868389eb7e', '9eab9018-9a40-4750-8765-4ba27609c1be',
      'c8f6949d-15a3-4541-b68d-6514300247a8', '4f46fdfe-9d6d-4406-9aa9-b2fc5100dc0a', '8689f1c4-9527-421a-8746-0e0378eee179', 'ab9a01b2-a81d-401b-9603-b3738b8d5252', '39d47e85-66c6-4ff1-a256-1caf04ff9ca4', '53e4ea34-85e4-4a48-b6ab-5da05bccc208', 'e8a1d73b-e795-4b7c-8c7e-b7b9346b0c6b', '30bffb80-49a1-4cd3-bf54-68f1d9c43d03', '3c61ea21-a6ed-43fb-a317-84a7d3872c7b', '2ebac984-b765-4adb-83ce-8c807b06212b', '70b9e300-2bef-4d59-b417-afcb99b56524', 'a71a2c71-c27f-45e8-b8e5-79ae12d75b23', 'cd15e3a2-609c-48ff-a9b4-656d89c92dca', '1b7bf176-2cbd-49fe-91ba-3095b5bc6e5f', 'bac23301-f256-4f43-9989-2a4c02b94746', 'b18869b9-f965-4d47-b155-0a435c9382d8', 'f1d4e2ee-d6d8-4a82-ab6a-004d060bcaa1', 'cec5c86d-b0ed-4bb1-9d15-99772111af22', '428fb07b-e59e-40d9-b037-f65fa69b5c00', 'bdaa1d92-3665-445a-bcbe-8d3d6013c051', '7e4fa235-52a8-4702-b7be-e6cfc26cb52f', 'b330c4de-e626-4ec3-91ef-b4957b67811f', 'b828ca4c-8c18-4011-8c91-5d5d7dec51a5', '9801af6c-5ddf-40b1-8771-7228fa7ae22e',
      'e675e27d-cd88-4e5f-a36b-799bdf65daed', 'b310668d-582e-4ba2-b219-7e0ac46af20b', 'e910f684-a5a2-4849-9b16-faab2c1ebaa4', '680035e9-bd81-4886-9fe6-1db6f9d8e381', 'db771c76-8f5e-4970-950c-2f71c5f04f0d', '755980ca-76a7-47a3-80ce-6d47701a786e', 'cfcbcdaa-3c9e-42d8-a4d4-d178e58f2d87', '40023f7d-44e4-4e05-aa9b-daf67372c066', 'c0891cd3-18af-4245-af5d-1b5f9810da14', 'ed1eb091-1ea9-4dc1-b1bd-5f08ce084473', 'b90fa3fb-804c-43e4-904c-65a622d56628', 'bd96b012-3d2a-479c-ac57-676a685d7f6c', 'b6948095-bcfb-40f3-aa9d-f439e393d6a7', 'd8dc805b-3c6a-4610-93d8-1565d3ff0c59', 'a44eadca-17b2-48e1-8614-2ed26781f1c6', 'e5ac2dea-b098-4a0c-8417-3d927063f119', 'd5a294ad-8e24-48ca-8263-dd692353e286', 'feb88ff2-7adb-43c3-af28-b0f6314fe9f0', '8427ddbd-8ebf-4b2f-a4fd-f47ff3e49546', 'b85e823b-852c-48d7-b921-98d5c567baca', '00c35aa3-1d0f-4f13-8575-09f81443268f', '7134271c-e158-4e49-bd24-7171ba39a892', '2db3a828-80e1-49ff-ba15-c99d6fdd6a58', '3b2c967c-3a3d-4be4-a2fc-08877d602fab',
      'b6b21ea1-f732-44b0-956f-eace323b428d', '95251c65-d411-4d7c-84ca-97cbd7eb727e', 'da6b89a0-88c5-4cdf-9312-85d0cf731dc2', 'c60202fe-6532-4945-b899-b00bcf3190fb', '0b45fb9e-ee5e-41eb-b278-abcac59aa586', '2c602a70-c9e8-40dc-9f89-7ab5d972705b', '95eaaf2e-e303-4104-81ff-361612b8e241', 'e8bf6842-5417-463f-bd1f-59b1378d09bc', '721b6126-5cf3-4570-ac33-d455cc32c416', '2c14d72e-7789-45a4-9000-d511736155bf', '68d0be99-37be-4936-bfee-fa0ce6eea3c5', '953130f9-3c86-4010-8b68-7ba5ddffaa98', '016f5d4b-2141-449e-a28f-e28e0aca289e', '3dbb27e9-c33e-4284-8545-39d2d3f0996d', 'fc7c92ca-e962-41b3-9394-7d37b3c6279f', 'bb939b70-f5d8-4ce1-9ff7-a6a7599c136c', '2611167f-a8c7-4fd0-9f99-dd39123e101d', 'e5cdac6f-63ef-48a9-b20d-b741ef07933d', '298129d5-7893-447f-80ee-a7a67c5f0760', '775690bb-2eb9-44fd-bdb1-2717e2c14d12', 'b4cf0728-bce7-47a7-92cf-a50fe48576b8', 'f20f07db-076d-4b51-909a-07a38157faf8', 'a57e1565-6c9e-4519-834b-7cf192a7294b', 'e90d7a51-55df-424e-a28a-19e088a5e13a',
      '76d0c1b1-b92c-4b9e-bf99-f781617e3907', 'e0f7d9ec-c00b-4512-bbf5-fd9dfbab38db', 'b7f181ed-ed67-4437-b3fc-50a322671661', 'bb3bde8f-d8f5-4ce5-aa4e-993b7d42df41', 'f94db700-1cdf-4f4d-bf25-2581b70b89e6', '8acafedc-8008-451c-9105-22e85cf56e36', 'ac1b8e34-47eb-4223-bd3c-29a3f8268fc3', 'b0166770-c2b8-44d9-9e80-705c79249ef4', '4e3a1b88-0252-4d15-b16f-1919cafb0c37', 'b53c6bfe-694a-4d35-a5b2-368407adf45b', '04017c17-8799-4086-9e38-54440b977cd3', '094674a8-ce7c-452c-bae5-545d7193c36a', 'd1ae2bf1-f117-4209-8ceb-c9aee3c563b3', 'eb2c402b-202b-4351-ba41-775776743181', '14a4adf7-6bad-477b-8a11-d4c242f152d4', '28f8ba5b-cd73-4dc8-8aba-6a15e56ffbd1', '1f2843f5-2326-4e02-823c-28cfeabb4b40', '84b72c0c-6bba-4447-ad4c-57d651d90616', 'fc5f91de-4776-4f95-8f09-c16f0410b9b4', '3127e98a-3658-4bfe-91dc-75204507ec0e', 'c6a3f064-1679-414f-a94f-6f749a0211e8', '51d6eaab-fb66-4d21-8a11-1b51811d2952', '1485f08a-8e71-4f55-a650-365ece897cd4', 'ed62655e-bc50-4817-bb93-28f545d4e66e',
      '278746ab-d51d-44b1-b1ae-edd3047a8fe8', '56612202-5fd6-4d9a-9c2f-3cf5879085f1', '25c67c70-45a9-4e96-af60-4a33401644da', 'f79609f7-31f6-47a3-b014-6b03052fed4a', 'a7409be3-ca56-4c6a-b633-2c5c2060d4aa', 'ea107814-adc3-4ed6-9df9-08fe75e8f694', 'de18491c-d5e8-4880-8d96-02ec7ee5f432', '767d1bc4-1682-4634-bb14-edf8920832e2', '27571368-313f-4ed9-9da5-6938689b3853', '5cf7212e-793e-4fd6-b7e5-ce3c018b7a2b', '807948f5-1afc-4b1c-9efd-716770071a55', '20d419d9-fb34-4bea-8210-172651091984', 'b15b7244-1924-41fa-92f5-8d52e0f089d1', 'fbad61de-2708-4c76-be24-43894b8022d4', 'fc35b17d-a7b9-4f39-a443-032dbbbcfb1d', '56428dfc-e6e5-474b-84c2-c5dbc6627f14', '4b08dc7a-d00e-4bc1-ac21-c5d931d7ab5a', 'a3986aaf-055b-4d47-a3ce-4bc1424997be', '9e36aed1-8808-42a3-bd78-9fd0330ee0a1', '142b5424-ac69-419a-9640-bd50b8dc9e39', '50de27c4-78e6-4ae2-a1f7-ac7bdb23845a', 'a0ecaa11-0d22-4a91-ad96-13c7992ac183', '35738482-5f4e-489b-9069-10136565f2ed', '73a99afd-0f14-4ff2-b00d-acc51a7d16bf',
      'd54601f2-339a-40fe-8da8-46f64d8daab0', '70ef4846-c89c-4256-90c4-a97b93aa8481', '4406bc8b-d69f-470b-b7a3-c41fbd5c1cc9', '0d3d3785-797d-492a-8977-b4f1877c464f', 'ec698139-f5e7-4043-b9b6-e666933f1494', '8bf7eabf-e267-4b7b-aad0-ec8816a97754', '04a0bf69-1c09-484f-a0db-0a028d782f45', '6e5e040d-85f5-4cd6-8db2-8cdb9319aa73', '3f84a541-9bf7-4e9b-9b88-204263e5153c', 'ddcec3c8-89ce-4e99-98b0-462f1e32408b', 'c584ed60-ca9e-4e50-93bc-3b04623f658f', 'f5be0442-408f-4084-9ebc-4de39e8cd925', '2fa1f0f7-0aa1-4730-9cbe-ccb21fd4f795', 'aa76b99b-f168-425e-9d95-b5a00376095f', 'a828d529-0b3e-4627-a50c-d6caf25defc6', '1ef31491-8d03-4c74-a50c-60ebcac37dd9', '67402988-8449-462b-b904-b3781a88dbf9', '9ed083fd-ad0b-4f76-8110-7ac4c5d944b4', '5731b5c2-ef28-4da8-90af-3e1cd6efaa2c', 'bbaceeaa-e9e8-4d47-9cc4-09c85d602ebc', '6ea684ad-aa39-48a2-b47e-d2ee0ff8c811', 'dcda3719-06aa-4c6a-a0c8-e44e93290fe2'
    ]

    SubmissionVersion.where(application_id: ids, version: 1).each do |version|
      puts "Updating ID: #{version.application_id}, Version: #{version.version} from #{version.application['updated_at']} to #{version.created_at}"
      version.application['updated_at'] = version.created_at
      version.save(touch: false) if ENV['PERSIST_ADJUSTMENT']
    end
  end

  desc "provider_updated after approval - incorrect data was not visible in app so good to apply to eariler versions"
  task fix_provider_updated: :environment do
    v1, v2, v3 = SubmissionVersion.where(application_id: 'a67d8256-fdea-4cda-bb2f-8b5786cde74b').order(:version)
    quote_id = '20844ebe-3dff-45d0-9548-020eb60bdf30'

    v1.application['quotes'] = v1.application['quotes'].select { _1['id'] == quote_id }
    v2.application['quotes'] = v2.application['quotes'].select { _1['id'] == quote_id }

    raise "Quote not found v1" if v1.application['quotes'].count != 1
    raise "Quote not found v2" if v2.application['quotes'].count != 1

    if if ENV['PERSIST_ADJUSTMENT']
      v1.save(touch: false)
      v2.save(touch: false)
      v3.delete
    end
  end
end

