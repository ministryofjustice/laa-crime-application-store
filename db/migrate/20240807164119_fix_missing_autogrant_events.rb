class FixMissingAutograntEvents < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    events_to_create = [
      {
        submission_id: "7002428d-fe03-4d1b-9c49-9b0e29a9d4a7",
        event: {
          "id"=>"1088d52a-66da-4c23-94c1-4627a4f98e59",
          "submission_version"=>1,
          "primary_user_id"=>nil,
          "secondary_user_id"=>nil,
          "linked_type"=>nil,
          "linked_id"=>nil,
          "details"=>{"to"=>"auto_grant", "from"=>"submitted", "field"=>"state"},
          "created_at"=>"2024-07-05T14:23:32.814Z",
          "updated_at"=>"2024-07-05T14:23:32.814Z",
          :public=>false,
          :event_type=>"auto_decision"
        }
      },
      {
        submission_id: "deeb8420-376e-4d95-9216-d53026ece6dd",
        event: {
          "id"=>"ec9eb90f-8c07-45c8-862a-d8b5cc2c7e2d",
          "submission_version"=>1,
          "primary_user_id"=>nil,
          "secondary_user_id"=>nil,
          "linked_type"=>nil,
          "linked_id"=>nil,
          "details"=>{"to"=>"auto_grant", "from"=>"submitted", "field"=>"state"},
          "created_at"=>"2024-07-29T13:29:29.340Z",
          "updated_at"=>"2024-07-29T13:29:29.340Z",
          "public"=>nil,
          :public=>false,
          :event_type=>"auto_decision"
        }
      },
      {
        submission_id: "89ea4eaa-287b-40ce-bf45-5751d3fa5f0d",
        event: {
          "id"=>"03d0a6a4-953d-45b6-8b52-b6b6416e8b42",
          "submission_version"=>1,
          "primary_user_id"=>nil,
          "secondary_user_id"=>nil,
          "linked_type"=>nil,
          "linked_id"=>nil,
          "details"=>{"to"=>"auto_grant", "from"=>"submitted", "field"=>"state"},
          "created_at"=>"2024-07-30T06:50:32.772Z",
          "updated_at"=>"2024-07-30T06:50:32.772Z",
          "public"=>nil,
          :public=>false,
          :event_type=>"auto_decision"
        }
      },
      {
        submission_id: "c835f92b-7971-4b51-a7fc-d289ff7c781f",
        event: {
          "id"=>"956e1240-71cc-430c-b254-b0540b3d7a29",
          "submission_version"=>1,
          "primary_user_id"=>nil,
          "secondary_user_id"=>nil,
          "linked_type"=>nil,
          "linked_id"=>nil,
          "details"=>{"to"=>"auto_grant", "from"=>"submitted", "field"=>"state"},
          "created_at"=>"2024-07-31T08:22:59.487Z",
          "updated_at"=>"2024-07-31T08:22:59.487Z",
          "public"=>nil,
          :public=>false,
          :event_type=>"auto_decision"
        }
      },
      {
        submission_id: "de68e4b0-bde7-49aa-8991-c8f174bbdb65",
        event: {
          "id"=>"4e258671-9905-4c19-8748-2b9fcb3f3ca3",
          "submission_version"=>1,
          "primary_user_id"=>nil,
          "secondary_user_id"=>nil,
          "linked_type"=>nil,
          "linked_id"=>nil,
          "details"=>{"to"=>"auto_grant", "from"=>"submitted", "field"=>"state"},
          "created_at"=>"2024-08-02T07:47:24.251Z",
          "updated_at"=>"2024-08-02T07:47:24.251Z",
          "public"=>nil,
          :public=>false,
          :event_type=>"auto_decision"
        }
      }
    ]

    events_to_create.each do |submission_data|
      begin
        submission_to_update = Submission.find(submission_data[:submission_id])
        if submission_to_update.present?
          submission_to_update.events << submission_data[:event].as_json
          submission_to_update.save(touch: false)
          sleep(0.001)  # throttle
        end
      rescue ActiveRecord::RecordNotFound => e
        false
      end
    end
  end
end
